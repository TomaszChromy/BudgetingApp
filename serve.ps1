param(
  [int]$Port = 5173,
  [switch]$AutoPort = $true,
  [string]$Root = (Get-Location).Path,
  [switch]$SpaFallback = $true
)

# --- MIME ---
$mime = @{
  ".html"="text/html"; ".htm"="text/html"; ".js"="text/javascript"; ".mjs"="text/javascript";
  ".css"="text/css"; ".json"="application/json"; ".png"="image/png"; ".jpg"="image/jpeg";
  ".jpeg"="image/jpeg"; ".svg"="image/svg+xml"; ".ico"="image/x-icon"; ".map"="application/json";
  ".txt"="text/plain"; ".wasm"="application/wasm"; ".csv"="text/csv"; ".webp"="image/webp"
}
function Get-Bytes($p){ try { [IO.File]::ReadAllBytes($p) } catch { $null } }
function Get-ContentType($p){ $e=[IO.Path]::GetExtension($p).ToLowerInvariant(); if($mime.ContainsKey($e)){$mime[$e]}else{"application/octet-stream"} }

# --- Spróbuj zająć port (autoport) ---
$tcp = $null
$maxTries = 200
for($i=0; $i -lt $maxTries; $i++){
  try{
    $tcp = [Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback, $Port)
    $tcp.Start()
    break
  } catch {
    if(-not $AutoPort){ throw "Port $Port zajęty. Użyj innego -Port albo uruchom z -AutoPort." }
    $Port++
  }
}
if(-not $tcp){ throw "Nie znalazłem wolnego portu (próby: $maxTries)." }

Write-Host "Serwer (TCP) działa: http://localhost:$Port/  (katalog: $Root)" -ForegroundColor Green
try { Start-Process "http://localhost:$Port/" | Out-Null } catch {}

# --- Główna pętla ---
while ($true) {
  $client = $tcp.AcceptTcpClient()
  try {
    $stream = $client.GetStream()
    $reader = [IO.StreamReader]::new($stream)

    # 1 linia: "GET /path HTTP/1.1"
    $reqLine = $reader.ReadLine()
    if (-not $reqLine) { continue }

    # wczytaj nagłówki do końca pustej linii
    while ($true) { $line = $reader.ReadLine(); if ([string]::IsNullOrEmpty($line)) { break } }

    $parts = $reqLine -split " "
    $reqPath = if ($parts.Length -ge 2) { $parts[1] } else { "/" }

    # dekoduj, obetnij query, zabezpiecz
    $reqPath = [Uri]::UnescapeDataString(($reqPath.Split("?")[0]))
    if ($reqPath -eq "/") { $reqPath = "/index.html" }
    $safe = $reqPath.TrimStart('/').Replace('/', '\')
    if ($safe -match "\.\.") { $safe = "index.html" }

    $full = Join-Path $Root $safe
    if (-not (Test-Path $full) -and $SpaFallback) {
      $full = Join-Path $Root "index.html"
    }

    if (Test-Path $full) {
      $bytes = Get-Bytes $full
      if ($null -eq $bytes) { $bytes = [byte[]]@() }
      $ctype = Get-ContentType $full
      $hdr = "HTTP/1.1 200 OK`r`nContent-Type: $ctype`r`nContent-Length: $($bytes.Length)`r`nConnection: close`r`n`r`n"
      $h = [Text.Encoding]::ASCII.GetBytes($hdr)
      $stream.Write($h,0,$h.Length)
      $stream.Write($bytes,0,$bytes.Length)
    } else {
      $msg = [Text.Encoding]::UTF8.GetBytes("Not Found")
      $hdr = "HTTP/1.1 404 Not Found`r`nContent-Type: text/plain; charset=utf-8`r`nContent-Length: $($msg.Length)`r`nConnection: close`r`n`r`n"
      $h = [Text.Encoding]::ASCII.GetBytes($hdr)
      $stream.Write($h,0,$h.Length)
      $stream.Write($msg,0,$msg.Length)
    }
  } finally {
    $client.Close()
  }
}
