param(
  [int]$Port = 5173,
  [string]$Root = (Get-Location).Path
)

$mime = @{
  ".html"="text/html"; ".htm"="text/html"; ".js"="text/javascript"; ".mjs"="text/javascript";
  ".css"="text/css"; ".json"="application/json"; ".png"="image/png"; ".jpg"="image/jpeg";
  ".jpeg"="image/jpeg"; ".svg"="image/svg+xml"; ".ico"="image/x-icon"; ".map"="application/json";
  ".txt"="text/plain"; ".wasm"="application/wasm"
}

function Get-Bytes($p){ try { [IO.File]::ReadAllBytes($p) } catch { $null } }
function Get-ContentType($p){ $e=[IO.Path]::GetExtension($p).ToLowerInvariant(); if($mime.ContainsKey($e)){$mime[$e]}else{"application/octet-stream"} }

Write-Host "Startuję prosty serwer (TcpListener) na http://localhost:$Port/  (root: $Root)" -ForegroundColor Green
$tcp = [Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback, $Port)
$tcp.Start()
try { Start-Process "http://localhost:$Port/" | Out-Null } catch {}

while ($true) {
  $client = $tcp.AcceptTcpClient()
  $stream = $client.GetStream()
  $reader = New-Object IO.StreamReader($stream)
  $reqLine = $reader.ReadLine()
  if (-not $reqLine) { $client.Close(); continue }

  # zignoruj nagłówki
  while ($true) { $line = $reader.ReadLine(); if ([string]::IsNullOrEmpty($line)) { break } }

  $parts = $reqLine -split " "
  $reqPath = if ($parts.Length -ge 2) { $parts[1] } else { "/" }
  if ($reqPath -eq "/") { $reqPath = "/index.html" }

  # usuń query string, zdekoduj URL i zabezpiecz przed .. 
  $reqPath = $reqPath.Split("?")[0]
  $reqPath = [Uri]::UnescapeDataString($reqPath)
  $safe = $reqPath.TrimStart('/').Replace('/', '\')
  if ($safe -match "\.\.") { $safe = "index.html" }

  $full = Join-Path $Root $safe
  if (Test-Path $full) {
    $bytes = Get-Bytes $full
    $ctype = Get-ContentType $full
    $hdr = "HTTP/1.1 200 OK`r`nContent-Type: $ctype`r`nContent-Length: $($bytes.Length)`r`nConnection: close`r`n`r`n"
    $h = [Text.Encoding]::ASCII.GetBytes($hdr)
    $stream.Write($h,0,$h.Length)
    $stream.Write($bytes,0,$bytes.Length)
  } else {
    $msg = [Text.Encoding]::UTF8.GetBytes("Not Found")
    $hdr = "HTTP/1.1 404 Not Found`r`nContent-Type: text/plain`r`nContent-Length: $($msg.Length)`r`nConnection: close`r`n`r`n"
    $h = [Text.Encoding]::ASCII.GetBytes($hdr)
    $stream.Write($h,0,$h.Length)
    $stream.Write($msg,0,$msg.Length)
  }
  $client.Close()
}
