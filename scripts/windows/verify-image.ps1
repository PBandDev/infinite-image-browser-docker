param(
  [Parameter(Mandatory = $true)][string]$ImageRef,
  [string]$ExpectedTag = "",
  [Nullable[int]]$Port = $null
)

$ErrorActionPreference = 'Stop'
$name = "iib-verify-$PID"

try {
  $publishBinding = if ($null -ne $Port) { "127.0.0.1:$Port:8080" } else { '127.0.0.1::8080' }
  $runArgs = @('run', '-d', '--rm', '--name', $name, '-p', $publishBinding, $ImageRef)
  & docker @runArgs | Out-Null
  if ($LASTEXITCODE -ne 0) {
    throw "verification failed: failed to start container '$name' from '$ImageRef'"
  }

  $hostPort = if ($null -ne $Port) {
    $Port
  } else {
    $portMapping = & docker port $name 8080/tcp
    if ($LASTEXITCODE -ne 0 -or -not $portMapping) {
      throw "verification failed: could not determine published local port for '$name'"
    }

    $firstMapping = ($portMapping | Select-Object -First 1).Trim()
    $firstMapping.Substring($firstMapping.LastIndexOf(':') + 1)
  }

  $versionJson = $null
  for ($i = 0; $i -lt 60; $i++) {
    try {
      $versionJson = Invoke-RestMethod "http://127.0.0.1:$hostPort/infinite_image_browsing/version"
      break
    } catch {
      Start-Sleep -Seconds 2
    }
  }

  if (-not $versionJson) {
    throw "verification failed: timed out waiting for /infinite_image_browsing/version from '$ImageRef'"
  }

  if (-not $versionJson.hash) {
    throw "verification failed: expected /version.hash to be non-empty"
  }

  if ($ExpectedTag -and $versionJson.tag -ne $ExpectedTag) {
    throw "verification failed: expected tag '$ExpectedTag' but got '$($versionJson.tag)'"
  }

  $runtimeHash = "$($versionJson.hash)".Trim()
  $sourceHash = (& docker exec $name sh -lc 'git -C /app rev-parse HEAD').Trim()
  if ($LASTEXITCODE -ne 0) {
    throw "verification failed: failed to read git HEAD for /app"
  }

  if (-not $sourceHash) {
    throw "verification failed: expected git HEAD for /app to be non-empty"
  }

  if ($runtimeHash -ne $sourceHash) {
    throw "verification failed: expected runtime hash '$runtimeHash' to match /app HEAD '$sourceHash'"
  }

  $confRaw = & docker exec $name sh -lc 'cat /app/vue/src-tauri/tauri.conf.json'
  if ($LASTEXITCODE -ne 0) {
    throw "verification failed: failed to read /app/vue/src-tauri/tauri.conf.json"
  }

  $conf = $confRaw | ConvertFrom-Json
  $sourceVersion = "$($conf.package.version)".Trim()
  if (-not $sourceVersion) {
    throw "verification failed: expected source version from tauri.conf.json to be non-empty"
  }

  $needle = "version:`"$sourceVersion`""
  & docker exec $name sh -lc 'test -d /app/vue/dist/assets'
  if ($LASTEXITCODE -ne 0) {
    throw 'verification failed: missing frontend assets directory /app/vue/dist/assets'
  }

  $jsFiles = & docker exec $name sh -lc "find /app/vue/dist/assets -type f -name '*.js'"
  if ($LASTEXITCODE -ne 0) {
    throw 'verification failed: failed to enumerate frontend JS assets under /app/vue/dist/assets'
  }

  if (-not $jsFiles) {
    throw 'verification failed: no frontend JS assets found under /app/vue/dist/assets'
  }

  $bundleMatches = & docker exec $name sh -lc "find /app/vue/dist/assets -type f -name '*.js' -exec grep -l -F -- '$needle' {} +" 2>&1
  $bundleExit = $LASTEXITCODE
  switch ($bundleExit) {
    0 {
      if (-not $bundleMatches) {
        throw 'verification failed: frontend bundle inspection returned success without any matching JS assets'
      }
      break
    }
    1 { throw "verification failed: expected frontend bundle to embed $needle" }
    default {
      $detail = if ($bundleMatches) { ": $($bundleMatches -join [Environment]::NewLine)" } else { '' }
      throw "verification failed: failed to scan frontend JS assets under /app/vue/dist/assets$detail"
    }
  }
} finally {
  docker rm -f $name | Out-Null 2>$null
}
