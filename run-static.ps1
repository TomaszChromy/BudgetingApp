param(
  [ValidateSet("auto","http","tcp")] [string]$Mode = "auto",
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

function Start-Http {
  param([int]$Port,[string]$Root)
  try { $null = [System.Net.HttpListener] } catch { throw "HttpListenerMissing" }
  $listener=[System.Net.HttpListener]::new()
  $prefix="http://localhost:$Port/"
  try { $listener.Prefixes.Add($prefix); $listener.Start() } catch { throw "HttpBindFail" }
  Write-Host "Serwer (HttpListener): $prefix  (katalog: $Root)" -ForegroundColor Green
  try{ Start-Process $prefix | Out-Null }catch{}
  try {
    while($listener.IsListening){
      $ctx=$listener.GetContext()
      $path=$ctx.Request.Url.AbsolutePath; if($path -eq "/"){ $path="/index.html" }
      $safe=$path.Replace('/',[IO.Path]::DirectorySeparatorChar).TrimStart([IO.Path]::DirectorySeparatorChar)
      $full=Join-Path $Root $safe
      if(-not (Test-Path $full)){
        $msg=[Text.Encoding]::UTF8.GetBytes("404 Not Found")
        $ctx.Response.StatusCode=404; $ctx.Response.ContentType="text/plain"; $ctx.Response.ContentLength64=$msg.Length
        $ctx.Response.OutputStream.Write($msg,0,$msg.Length); $ctx.Response.Close(); continue
      }
      $bytes=Get-Bytes $full; $ctype=Get-ContentType $full
      $ctx.Response.StatusCode=200; $ctx.Response.ContentType=$ctype; $ctx.Response.ContentLength64=$bytes.Length
      $ctx.Response.OutputStream.Write($bytes,0,$bytes.Length); $ctx.Response.Close()
    }
  } finally { if($listener){ $listener.Stop(); $listener.Close() } }
}

function Start-Tcp {
  param([int]$Port,[string]$Root)
  $ip=[Net.IPAddress]::Loopback; $tcp=[Net.Sockets.TcpListener]::new($ip,$Port)
  try { $tcp.Start() } catch { throw "TcpBindFail" }
  Write-Host "Serwer (TcpListener): http://localhost:$Port/  (katalog: $Root)" -ForegroundColor Green
  try{ Start-Process "http://localhost:$Port/" | Out-Null }catch{}
  while($true){
    $c=$tcp.AcceptTcpClient(); $s=$c.GetStream()
    $r=New-Object IO.StreamReader($s); $req=$r.ReadLine(); if(-not $req){ $c.Close(); continue }
    while($true){ $h=$r.ReadLine(); if([string]::IsNullOrEmpty($h)){ break } }
    $path=($req -split " ")[1]; if($path -eq "/"){ $path="/index.html" }
    $full=Join-Path $Root ($path.TrimStart('/').Replace('/','\'))
    if(Test-Path $full){
      $bytes=Get-Bytes $full; $ctype=Get-ContentType $full
      $hdr="HTTP/1.1 200 OK`r`nContent-Type: $ctype`r`nContent-Length: $($bytes.Length)`r`nConnection: close`r`n`r`n"
      $hb=[Text.Encoding]::ASCII.GetBytes($hdr); $s.Write($hb,0,$hb.Length); $s.Write($bytes,0,$bytes.Length)
    } else {
      $msg=[Text.Encoding]::UTF8.GetBytes("Not Found")
      $hdr="HTTP/1.1 404 Not Found`r`nContent-Type: text/plain`r`nContent-Length: $($msg.Length)`r`nConnection: close`r`n`r`n"
      $hb=[Text.Encoding]::ASCII.GetBytes($hdr); $s.Write($hb,0,$hb.Length); $s.Write($msg,0,$msg.Length)
    }
    $c.Close()
  }
}

switch ($Mode) {
  "http" { Start-Http -Port $Port -Root $Root }
  "tcp"  { Start-Tcp  -Port $Port -Root $Root }
  default {
    try { Start-Http -Port $Port -Root $Root }
    catch {
      if ($_.Exception.Message -in @("HttpListenerMissing","HttpBindFail")) {
        Write-Host "Przełączam na fallback TcpListener…" -ForegroundColor Yellow
        Start-Tcp -Port $Port -Root $Root
      } else { throw }
    }
  }
}
