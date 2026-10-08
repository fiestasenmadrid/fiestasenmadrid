# Servidor local para ver la web antes de publicarla: http://localhost:8080
param([int]$Puerto = 8080, [string]$Raiz = (Join-Path $PSScriptRoot 'public'))
$tipos = @{ '.html' = 'text/html; charset=utf-8'; '.css' = 'text/css'; '.js' = 'text/javascript'; '.xml' = 'application/xml'; '.txt' = 'text/plain; charset=utf-8' }
$http = New-Object Net.HttpListener
$http.Prefixes.Add("http://localhost:$Puerto/")
$http.Prefixes.Add("http://127.0.0.1:$Puerto/")
$http.Start()
Write-Host "Sirviendo $Raiz en http://localhost:$Puerto/"
while ($http.IsListening) {
  $ctx = $http.GetContext()
  $ruta = [Uri]::UnescapeDataString($ctx.Request.Url.AbsolutePath)
  $archivo = Join-Path $Raiz $ruta.TrimStart('/')
  if (Test-Path $archivo -PathType Container) { $archivo = Join-Path $archivo 'index.html' }
  $codigo = 200
  if (-not (Test-Path $archivo -PathType Leaf)) { $archivo = Join-Path $Raiz '404.html'; $codigo = 404 }
  $bytes = [IO.File]::ReadAllBytes($archivo)
  $tipo = $tipos[[IO.Path]::GetExtension($archivo)]
  if (-not $tipo) { $tipo = 'application/octet-stream' }
  $ctx.Response.StatusCode = $codigo
  $ctx.Response.ContentType = $tipo
  $ctx.Response.ContentLength64 = $bytes.Length
  $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
  $ctx.Response.Close()
}
