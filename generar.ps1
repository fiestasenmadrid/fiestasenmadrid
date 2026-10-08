<#
  Genera la web estática de fiestas a partir de fiestas.tsv y la deja en la carpeta "public".

  Uso:
    Windows:  powershell -ExecutionPolicy Bypass -File generar.ps1
    Linux/CI: pwsh ./generar.ps1

  Variables de entorno (opcionales, sobrescriben la configuración de abajo):
    SITE_URL   Dirección pública de la web, p. ej. https://fiestasmadridhoy.com
    RRPP_URL   Tu perfil RRPP de Fourvenues. Si no existe se lee del archivo rrpp.txt
#>
param(
  [string]$Datos = (Join-Path $PSScriptRoot 'fiestas.tsv'),
  [string]$Salida = (Join-Path $PSScriptRoot 'public')
)
$ErrorActionPreference = 'Stop'

# ------------------------------------------------------------------ Configuración
$Marca   = 'Fiestas en Madrid'
$SiteUrl = 'https://fiestasenmadrid.com'
# Fiestas que salen en tu perfil pero no son en Madrid (se comparan en mayúsculas)
$Excluir = @('MALLORCA', 'DENIA', 'VALLADOLID')
$ImgBase = 'https://fourvenues.com/cdn-cgi/imagedelivery/kWuoTchaMsk7Xnc_FNem7A/'

if ($env:SITE_URL) { $SiteUrl = $env:SITE_URL }
$RrppUrl = $env:RRPP_URL
$rrppFile = Join-Path $PSScriptRoot 'rrpp.txt'
if (-not $RrppUrl -and (Test-Path $rrppFile)) { $RrppUrl = (Get-Content $rrppFile -Raw).Trim() }
if (-not $RrppUrl) { throw 'Falta tu link de RRPP: crea rrpp.txt o define la variable RRPP_URL.' }
$SiteUrl = $SiteUrl.TrimEnd('/')
$RrppUrl = $RrppUrl.TrimEnd('/')
$Base = ([Uri]$SiteUrl).AbsolutePath.TrimEnd('/')

# ------------------------------------------------------------------ Fechas
$Tz = $null
foreach ($id in 'Europe/Madrid', 'Romance Standard Time') {
  try { $Tz = [TimeZoneInfo]::FindSystemTimeZoneById($id); break } catch { }
}
$Ahora = [TimeZoneInfo]::ConvertTimeFromUtc([DateTime]::UtcNow, $Tz)
# Hasta las 8:00 la noche anterior sigue contando como "hoy"
$Hoy = $Ahora.AddHours(-8).Date

$DiasSem  = 'domingo', 'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado'
$DiasSlug = 'domingo', 'lunes', 'martes', 'miercoles', 'jueves', 'viernes', 'sabado'
$Meses    = '', 'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'

function Cap([string]$s) { if ($s) { $s.Substring(0, 1).ToUpper() + $s.Substring(1) } else { $s } }
function DiaSem([datetime]$d) { $DiasSem[[int]$d.DayOfWeek] }
function FechaLarga([datetime]$d) { '{0} {1} de {2}' -f (DiaSem $d), $d.Day, $Meses[$d.Month] }
function Iso([datetime]$d) {
  $o = $Tz.GetUtcOffset($d)
  $signo = '+'; if ($o -lt [TimeSpan]::Zero) { $signo = '-' }
  $d.ToString('yyyy-MM-ddTHH:mm:ss', [Globalization.CultureInfo]::InvariantCulture) + $signo + $o.Duration().ToString('hh\:mm')
}
function Etiqueta-Dia([datetime]$d) {
  $dif = ($d - $Hoy).Days
  if ($dif -eq 0) { return 'Hoy' }
  if ($dif -eq 1) { return 'Mañana' }
  Cap (FechaLarga $d)
}

# ------------------------------------------------------------------ Utilidades
function Esc($s) { [Net.WebUtility]::HtmlEncode([string]$s) }

function Slug([string]$s) {
  $n = $s.ToLowerInvariant().Normalize([Text.NormalizationForm]::FormD)
  $sb = New-Object Text.StringBuilder
  foreach ($c in $n.ToCharArray()) {
    if ([Globalization.CharUnicodeInfo]::GetUnicodeCategory($c) -ne [Globalization.UnicodeCategory]::NonSpacingMark) { [void]$sb.Append($c) }
  }
  $r = ($sb.ToString() -replace '[^a-z0-9]+', '-').Trim('-')
  if ($r.Length -gt 60) { $r = $r.Substring(0, 60).Trim('-') }
  $r
}

# Nombres en mayúsculas ("BLUE CLUB") se muestran como "Blue Club"
function Bonito([string]$s) {
  if ($s.Length -gt 3 -and $s -ceq $s.ToUpperInvariant()) {
    return (Get-Culture).TextInfo.ToTitleCase($s.ToLowerInvariant())
  }
  $s
}

function Leer-Hora([string]$s) {
  if ($s -match '^\s*(\d{1,2}):(\d{2})') { return New-Object TimeSpan ([int]$matches[1]), ([int]$matches[2]), 0 }
  $null
}

function Leer-Fecha([string]$s) {
  $d = [datetime]::MinValue
  $fmts = [string[]]@('yyyy-MM-dd', 'd/M/yyyy', 'dd/MM/yyyy', 'd/M/yy')
  if ([datetime]::TryParseExact($s.Trim(), $fmts, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::None, [ref]$d)) { return $d }
  $null
}

$Utf8 = New-Object Text.UTF8Encoding($false)
$Sitemap = New-Object System.Collections.Generic.List[string]

function Guardar([string]$ruta, [string]$contenido, [switch]$Indexar) {
  if ($ruta.EndsWith('/')) { $archivo = Join-Path $Salida (($ruta.Trim('/') + '/index.html').TrimStart('/')) }
  else { $archivo = Join-Path $Salida $ruta.TrimStart('/') }
  $dir = Split-Path $archivo
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force $dir | Out-Null }
  [IO.File]::WriteAllText($archivo, $contenido, $Utf8)
  if ($Indexar) { $Sitemap.Add($ruta) }
}

function U([string]$ruta) { "$Base$ruta" }        # enlace interno
function Abs([string]$ruta) { "$SiteUrl$ruta" }   # URL absoluta

function Json($obj) { $obj | ConvertTo-Json -Depth 8 -Compress }

# ------------------------------------------------------------------ Lectura de datos
$lineas = @([IO.File]::ReadAllLines($Datos, [Text.Encoding]::UTF8) | Where-Object { $_.Trim() })
$cab = @($lineas[0].Split("`t") | ForEach-Object { $_.Trim().ToLowerInvariant() })
$col = @{}
for ($i = 0; $i -lt $cab.Count; $i++) { $col[$cab[$i]] = $i }

function Campo($partes, [string]$nombre) {
  if (-not $col.ContainsKey($nombre) -or $col[$nombre] -ge $partes.Count) { return '' }
  $v = $partes[$col[$nombre]].Trim()
  if ($v.Length -gt 1 -and $v.StartsWith('"') -and $v.EndsWith('"')) { $v = $v.Substring(1, $v.Length - 2).Replace('""', '"') }
  $v
}

$lista = New-Object System.Collections.Generic.List[object]
$vistos = @{}
foreach ($l in ($lineas | Select-Object -Skip 1)) {
  $p = $l.Split("`t")
  $fecha = Leer-Fecha (Campo $p 'fecha')
  $ini = Leer-Hora (Campo $p 'inicio')
  $codigo = Campo $p 'codigo'
  $titulo = Campo $p 'titulo'
  $disco = Campo $p 'discoteca'
  if (-not $fecha -or $null -eq $ini -or -not $codigo -or -not $disco) { Write-Warning "Fila ignorada: $l"; continue }
  if ((Campo $p 'estado') -match 'cancel') { continue }
  if ($fecha -lt $Hoy) { continue }
  $mayus = "$titulo $disco".ToUpperInvariant()
  if (@($Excluir | Where-Object { $mayus.Contains($_) }).Count) { continue }
  if ($vistos.ContainsKey($codigo)) { continue }
  $vistos[$codigo] = $true
  if (-not $titulo) { $titulo = $disco }

  # Las fiestas que empiezan de madrugada (00:00) pertenecen a la noche de "fecha"
  $inicio = $fecha.Add($ini)
  if ($ini.Hours -lt 12) { $inicio = $inicio.AddDays(1) }
  $finH = Leer-Hora (Campo $p 'fin')
  $fin = $null
  if ($null -ne $finH) { $fin = $fecha.Add($finH); while ($fin -le $inicio) { $fin = $fin.AddDays(1) } }

  $img = Campo $p 'imagen'
  if ($img -and $img -notmatch '^https?://') { $img = "$ImgBase$img/width=534" }

  $discoBonito = Bonito $disco
  $horario = $ini.ToString('hh\:mm') + ' – '
  if ($null -ne $finH) { $horario += $finH.ToString('hh\:mm') } else { $horario += 'cierre' }

  $ruta = '/fiesta/{0}-{1}-{2}-{3}/' -f (Slug "$disco $titulo"), $fecha.Day, $Meses[$fecha.Month], $codigo.ToLowerInvariant()

  $lista.Add([pscustomobject]@{
      Fecha     = $fecha
      Inicio    = $inicio
      Fin       = $fin
      Horario   = $horario
      Titulo    = $titulo
      Disco     = $discoBonito
      DiscoSlug = (Slug $disco)
      Codigo    = $codigo
      Img       = $img
      Tipo      = $(if ($ini.Hours -ge 12 -and $ini.Hours -lt 21) { 'tardeo' } else { 'noche' })
      Ruta      = $ruta
      Compra    = "/entradas/$($codigo.ToLowerInvariant())/"
      Q         = ((Slug "$titulo $disco") -replace '-', ' ')
    })
}
$Eventos = @($lista | Sort-Object Inicio, Disco)
$Dias = @($Eventos | Group-Object { $_.Fecha.ToString('yyyy-MM-dd') } | Sort-Object Name)
$Discos = @($Eventos | Group-Object DiscoSlug | Sort-Object { -$_.Count }, Name)
Write-Host ("{0} fiestas en {1} días y {2} discotecas" -f $Eventos.Count, $Dias.Count, $Discos.Count)

# ------------------------------------------------------------------ Plantillas
$Menu = @(
  @('/fiestas-hoy-madrid/', 'Hoy'),
  @('/fiestas-fin-de-semana-madrid/', 'Finde'),
  @('/tardeo-madrid/', 'Tardeo'),
  @('/discotecas/', 'Discotecas')
)

function Pie {
  $sem = foreach ($i in 4, 5, 6, 0, 1, 2, 3) { '<a class="chip" href="{0}">Fiestas {1} Madrid</a>' -f (U "/fiestas-$($DiasSlug[$i])-madrid/"), $DiasSem[$i] }
  $top = foreach ($g in ($Discos | Select-Object -First 24)) { '<a class="chip" href="{0}">Entradas {1}</a>' -f (U "/discotecas/$($g.Name)/"), (Esc $g.Group[0].Disco) }
  @"
<footer><div class="wrap">
<h2>Fiestas en Madrid por día</h2>
<nav class="enlaces"><a class="chip" href="$(U '/fiestas-hoy-madrid/')">Fiestas hoy Madrid</a><a class="chip" href="$(U '/fiestas-fin-de-semana-madrid/')">Fin de semana</a><a class="chip" href="$(U '/tardeo-madrid/')">Tardeo Madrid</a>$($sem -join '')</nav>
<h2>Discotecas en Madrid</h2>
<nav class="enlaces">$($top -join '')<a class="chip" href="$(U '/discotecas/')">Ver todas</a></nav>
<p class="legal">$(Esc $Marca) es una agenda independiente de fiestas en Madrid. No es la web oficial de ninguna discoteca ni organizador. Las entradas se compran directamente en Fourvenues, la plataforma de venta de cada evento; precios, horarios y condiciones de acceso los fija cada sala. Actualizado el $(FechaLarga $Ahora) a las $($Ahora.ToString('HH:mm')).</p>
</div></footer>
"@
}

function Pagina {
  param([string]$Titulo, [string]$Desc, [string]$Ruta, [string]$Cuerpo, $JsonLd = $null, [string]$Imagen = '', [string]$Activo = '', [string]$ClaseBody = '')
  $menu = foreach ($m in $Menu) {
    $cur = ''; if ($m[0] -eq $Activo) { $cur = ' aria-current="page"' }
    '<a href="{0}"{2}>{1}</a>' -f (U $m[0]), $m[1], $cur
  }
  $ld = ''
  if ($JsonLd) { $ld = '<script type="application/ld+json">' + (Json $JsonLd) + '</script>' }
  $og = ''
  if ($Imagen) { $og = '<meta property="og:image" content="' + (Esc $Imagen) + '"><meta name="twitter:card" content="summary_large_image">' }
  $clase = ''
  if ($ClaseBody) { $clase = " class=`"$ClaseBody`"" }
  @"
<!doctype html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>$(Esc $Titulo)</title>
<meta name="description" content="$(Esc $Desc)">
<link rel="canonical" href="$(Abs $Ruta)">
<meta name="theme-color" content="#0a0a10">
<meta property="og:type" content="website">
<meta property="og:locale" content="es_ES">
<meta property="og:site_name" content="$(Esc $Marca)">
<meta property="og:title" content="$(Esc $Titulo)">
<meta property="og:description" content="$(Esc $Desc)">
<meta property="og:url" content="$(Abs $Ruta)">
$og
<link rel="icon" href="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'%3E%3Ctext y='.9em' font-size='90'%3E%F0%9F%AA%A9%3C/text%3E%3C/svg%3E">
<link rel="stylesheet" href="$(U '/estilos.css')">
$ld
</head>
<body$clase>
<header class="top"><div class="wrap">
<a class="logo" href="$(U '/')">fiestasen<span>madrid</span></a>
<nav class="menu" aria-label="Secciones">$($menu -join '')</nav>
</div></header>
<main>
$Cuerpo
</main>
$(Pie)
<script src="$(U '/app.js')" defer></script>
</body>
</html>
"@
}

function Tarjeta($e) {
  $img = '<span class="poster"></span>'
  if ($e.Img) { $img = '<a class="poster" href="{0}" tabindex="-1" aria-hidden="true"><img src="{1}" alt="" loading="lazy" decoding="async" width="534" height="668"></a>' -f (U $e.Ruta), (Esc $e.Img) }
  @"
<article class="card" data-q="$(Esc $e.Q)" data-tipo="$($e.Tipo)">
$img
<div class="info">
<p class="hora">$(Esc $e.Horario)</p>
<h3><a href="$(U $e.Ruta)">$(Esc $e.Titulo)</a></h3>
<p class="lugar"><a href="$(U "/discotecas/$($e.DiscoSlug)/")">$(Esc $e.Disco)</a></p>
<a class="btn" href="$(U $e.Compra)" rel="nofollow sponsored">Entradas</a>
</div>
</article>
"@
}

function Rejilla($evs) { '<div class="grid">' + ((@($evs) | ForEach-Object { Tarjeta $_ }) -join '') + '</div>' }

function PorDias($evs) {
  $grupos = @(@($evs) | Group-Object { $_.Fecha.ToString('yyyy-MM-dd') } | Sort-Object Name)
  $html = foreach ($g in $grupos) {
    $d = $g.Group[0].Fecha
    $et = Etiqueta-Dia $d
    $sub = ''
    if ($et -eq 'Hoy' -or $et -eq 'Mañana') { $sub = ' · ' + (FechaLarga $d) }
    @"
<section class="dia" id="d-$($g.Name)" data-fecha="$($g.Name)">
<h2>$(Esc $et)$(Esc $sub) <small>$($g.Count) fiestas</small></h2>
$(Rejilla $g.Group)
</section>
"@
  }
  $html -join "`n"
}

function ListaLd($evs) {
  $i = 0
  [ordered]@{
    '@context'        = 'https://schema.org'
    '@type'           = 'ItemList'
    'itemListElement' = @(@($evs) | ForEach-Object { $i++; [ordered]@{ '@type' = 'ListItem'; 'position' = $i; 'url' = (Abs $_.Ruta) } })
  }
}

function Listado {
  param([string]$Ruta, [string]$Titulo, [string]$H1, [string]$Intro, [string]$Desc, $Evs, [string]$Activo = '', [switch]$Buscador)
  $Evs = @($Evs)
  $cuerpo = ''
  if ($Evs.Count -eq 0) {
    $cuerpo = '<p class="vacio">Ahora mismo no hay fiestas publicadas para esta fecha. <a href="' + (U '/') + '">Ver todas las fiestas de Madrid</a></p>'
  } else {
    $cuerpo = PorDias $Evs
  }
  $busca = ''
  $chips = ''
  if ($Buscador -and $Evs.Count) {
    $busca = @"
<div class="buscador">
<input id="buscar" type="search" placeholder="Busca discoteca o fiesta…" aria-label="Buscar fiesta o discoteca" autocomplete="off">
<div class="filtros" role="group" aria-label="Tipo de fiesta"><button class="chip on" data-f="todo" aria-pressed="true">Todo</button><button class="chip" data-f="tardeo" aria-pressed="false">Tardeo</button><button class="chip" data-f="noche" aria-pressed="false">Noche</button></div>
</div>
"@
    $grupos = @($Evs | Group-Object { $_.Fecha.ToString('yyyy-MM-dd') } | Sort-Object Name)
    if ($grupos.Count -gt 1) {
      $c = foreach ($g in $grupos) {
        $d = $g.Group[0].Fecha
        $et = Etiqueta-Dia $d
        if ($et -ne 'Hoy' -and $et -ne 'Mañana') { $et = (Cap (DiaSem $d)).Substring(0, 3) + ' ' + $d.Day }
        '<a class="chip" href="#d-{0}" data-fecha="{0}">{1}</a>' -f $g.Name, (Esc $et)
      }
      $chips = '<div class="diasbar"><nav class="wrap dias" aria-label="Días">' + ($c -join '') + '</nav></div>'
    }
  }
  $img = ''
  $conImg = @($Evs | Where-Object { $_.Img } | Select-Object -First 1)
  if ($conImg.Count) { $img = $conImg[0].Img }
  $cuerpoFinal = @"
<div class="wrap hero">
<h1>$H1</h1>
<p>$(Esc $Intro)</p>
$busca
</div>
$chips
<div class="wrap">
$cuerpo
<p class="vacio" id="vacio" hidden>No hay fiestas que coincidan con tu búsqueda.</p>
</div>
"@
  $ld = $null
  if ($Evs.Count) { $ld = ListaLd $Evs }
  Guardar $Ruta (Pagina -Titulo $Titulo -Desc $Desc -Ruta $Ruta -Cuerpo $cuerpoFinal -JsonLd $ld -Imagen $img -Activo $Activo) -Indexar
}

# ------------------------------------------------------------------ Generación
if (Test-Path $Salida) { Remove-Item $Salida -Recurse -Force }
New-Item -ItemType Directory -Force $Salida | Out-Null
Copy-Item (Join-Path $PSScriptRoot 'estatico/*') $Salida -Recurse

$nDiscos = $Discos.Count

# Portada
Listado -Ruta '/' -Buscador -Evs $Eventos `
  -Titulo "Fiestas en Madrid hoy y esta semana – Entradas | $Marca" `
  -H1 'Fiestas en Madrid <em>hoy</em> y esta semana' `
  -Intro "$($Eventos.Count) fiestas en $nDiscos discotecas de Madrid. Elige día, mira el cartel y compra tu entrada online en un minuto. Actualizado cada día." `
  -Desc "Agenda diaria de fiestas en Madrid: $($Eventos.Count) fiestas esta semana en $nDiscos discotecas. Tardeos, afterworks y noche. Compra tus entradas online."

# Hoy
$hoyEvs = @($Eventos | Where-Object { $_.Fecha -eq $Hoy })
Listado -Ruta '/fiestas-hoy-madrid/' -Activo '/fiestas-hoy-madrid/' -Buscador -Evs $hoyEvs `
  -Titulo "Fiestas hoy en Madrid ($(FechaLarga $Hoy)) – Entradas | $Marca" `
  -H1 'Fiestas <em>hoy</em> en Madrid' `
  -Intro "$(Cap (FechaLarga $Hoy)): $($hoyEvs.Count) fiestas en Madrid para esta noche, del tardeo a la discoteca. Compra tu entrada online." `
  -Desc "¿Qué hacer hoy en Madrid? $($hoyEvs.Count) fiestas para hoy, $(FechaLarga $Hoy). Horarios, discotecas y entradas online."

# Cada día de la semana: la próxima fecha con ese día
for ($i = 0; $i -lt 7; $i++) {
  $d = $Hoy
  while ([int]$d.DayOfWeek -ne $i) { $d = $d.AddDays(1) }
  $evs = @($Eventos | Where-Object { $_.Fecha -eq $d })
  $nom = $DiasSem[$i]
  Listado -Ruta "/fiestas-$($DiasSlug[$i])-madrid/" -Buscador -Evs $evs `
    -Titulo "Fiestas $nom Madrid ($($d.Day) de $($Meses[$d.Month])) – Entradas | $Marca" `
    -H1 "Fiestas el <em>$nom</em> en Madrid" `
    -Intro "Las fiestas del $(FechaLarga $d) en Madrid: $($evs.Count) planes entre tardeos, afterworks y discotecas. Cada semana se actualiza solo." `
    -Desc "Fiestas en Madrid el $nom $($d.Day) de $($Meses[$d.Month]): $($evs.Count) fiestas con horarios y entradas online. Qué hacer el $nom por la noche en Madrid."
}

# Fin de semana (viernes a domingo)
$dw = [int]$Hoy.DayOfWeek
if ($dw -eq 6) { $vie = $Hoy.AddDays(-1) } elseif ($dw -eq 0) { $vie = $Hoy.AddDays(-2) } else { $vie = $Hoy.AddDays(5 - $dw) }
$dom = $vie.AddDays(2)
$finde = @($Eventos | Where-Object { $_.Fecha -ge $vie -and $_.Fecha -le $dom })
Listado -Ruta '/fiestas-fin-de-semana-madrid/' -Activo '/fiestas-fin-de-semana-madrid/' -Buscador -Evs $finde `
  -Titulo "Fiestas fin de semana Madrid ($($vie.Day)–$($dom.Day) de $($Meses[$dom.Month])) | $Marca" `
  -H1 'Fiestas este <em>fin de semana</em> en Madrid' `
  -Intro "Viernes, sábado y domingo: $($finde.Count) fiestas en Madrid este finde. Elige plan y compra tu entrada online." `
  -Desc "Planes de fiesta para el fin de semana en Madrid: $($finde.Count) fiestas del viernes $($vie.Day) al domingo $($dom.Day). Discotecas, tardeos y entradas."

# Tardeo
$tardeo = @($Eventos | Where-Object { $_.Tipo -eq 'tardeo' })
Listado -Ruta '/tardeo-madrid/' -Activo '/tardeo-madrid/' -Buscador -Evs $tardeo `
  -Titulo "Tardeo en Madrid: afterworks y fiestas de tarde | $Marca" `
  -H1 '<em>Tardeo</em> y afterwork en Madrid' `
  -Intro "Fiestas que empiezan por la tarde: $($tardeo.Count) tardeos y afterworks en Madrid esta semana." `
  -Desc "Los mejores tardeos y afterworks de Madrid esta semana: $($tardeo.Count) planes de tarde con horarios y entradas online."

# Discotecas
foreach ($g in $Discos) {
  $nom = $g.Group[0].Disco
  Listado -Ruta "/discotecas/$($g.Name)/" -Evs $g.Group `
    -Titulo "Entradas $nom Madrid – Próximas fiestas | $Marca" `
    -H1 "Entradas <em>$(Esc $nom)</em>" `
    -Intro "Próximas fiestas en $nom (Madrid): $($g.Count) fechas con horario. Compra tu entrada online antes de que se agoten." `
    -Desc "Entradas para $nom en Madrid. Próximas fiestas, horarios y venta de entradas online: $($g.Count) fechas disponibles."
}
$itemsDiscos = foreach ($g in ($Discos | Sort-Object { $_.Group[0].Disco })) {
  '<li><a href="{0}">{1} <span>{2} fiestas</span></a></li>' -f (U "/discotecas/$($g.Name)/"), (Esc $g.Group[0].Disco), $g.Count
}
$cuerpo = @"
<div class="wrap hero">
<h1>Discotecas en <em>Madrid</em></h1>
<p>$nDiscos discotecas y salas con fiestas esta semana. Entra en cada una para ver sus próximas fechas y comprar entradas.</p>
</div>
<div class="wrap"><ul class="lista-discos">$($itemsDiscos -join '')</ul></div>
"@
Guardar '/discotecas/' (Pagina -Titulo "Discotecas en Madrid: entradas y próximas fiestas | $Marca" -Desc "Listado de $nDiscos discotecas de Madrid con fiestas esta semana. Consulta fechas y compra entradas online." -Ruta '/discotecas/' -Cuerpo $cuerpo -Activo '/discotecas/') -Indexar

# Fichas de evento + redirecciones de compra
foreach ($e in $Eventos) {
  $fl = FechaLarga $e.Fecha
  $destino = "$RrppUrl/events/$($e.Codigo)"
  $finTxt = 'hasta el cierre'
  if ($e.Fin) { $finTxt = 'hasta las ' + $e.Fin.ToString('HH:mm') }

  $ld = [ordered]@{
    '@context'            = 'https://schema.org'
    '@type'               = 'Event'
    'name'                = "$($e.Titulo) – $($e.Disco)"
    'startDate'           = (Iso $e.Inicio)
    'eventStatus'         = 'https://schema.org/EventScheduled'
    'eventAttendanceMode' = 'https://schema.org/OfflineEventAttendanceMode'
    'location'            = [ordered]@{
      '@type'   = 'Place'
      'name'    = $e.Disco
      'address' = [ordered]@{ '@type' = 'PostalAddress'; 'addressLocality' = 'Madrid'; 'addressRegion' = 'Comunidad de Madrid'; 'addressCountry' = 'ES' }
    }
    'description'         = "$($e.Titulo) en $($e.Disco), Madrid. $(Cap $fl), de $($e.Horario.Replace(' – ', ' a '))."
    'organizer'           = [ordered]@{ '@type' = 'Organization'; 'name' = $e.Disco; 'url' = (Abs "/discotecas/$($e.DiscoSlug)/") }
    'offers'              = [ordered]@{ '@type' = 'Offer'; 'url' = (Abs $e.Compra); 'availability' = 'https://schema.org/InStock'; 'priceCurrency' = 'EUR' }
  }
  if ($e.Fin) { $ld['endDate'] = Iso $e.Fin }
  if ($e.Img) { $ld['image'] = @($e.Img) }

  $poster = '<span class="poster"></span>'
  if ($e.Img) { $poster = '<span class="poster"><img src="{0}" alt="Cartel de {1} en {2}" width="534" height="668"></span>' -f (Esc $e.Img), (Esc $e.Titulo), (Esc $e.Disco) }

  $mismaDisco = @($Eventos | Where-Object { $_.DiscoSlug -eq $e.DiscoSlug -and $_.Codigo -ne $e.Codigo } | Select-Object -First 4)
  $mismoDia = @($Eventos | Where-Object { $_.Fecha -eq $e.Fecha -and $_.Codigo -ne $e.Codigo -and $_.DiscoSlug -ne $e.DiscoSlug } | Select-Object -First 8)
  $extra = ''
  if ($mismaDisco.Count) { $extra += '<section class="seccion"><h2>Más fiestas en ' + (Esc $e.Disco) + '</h2>' + (Rejilla $mismaDisco) + '</section>' }
  if ($mismoDia.Count) { $extra += '<section class="seccion"><h2>Otras fiestas el ' + (Esc $fl) + '</h2>' + (Rejilla $mismoDia) + '<p><a class="chip" href="' + (U "/fiestas-$($DiasSlug[[int]$e.Fecha.DayOfWeek])-madrid/") + '">Ver todas las fiestas del ' + (Esc (DiaSem $e.Fecha)) + '</a></p></section>' }

  $cuerpo = @"
<div class="wrap">
<nav class="migas" aria-label="Ruta"><a href="$(U '/')">Fiestas Madrid</a> › <a href="$(U "/discotecas/$($e.DiscoSlug)/")">$(Esc $e.Disco)</a> › $(Esc $e.Titulo)</nav>
<article class="evento">
$poster
<div>
<h1>$(Esc $e.Titulo)</h1>
<p class="sub">en <a href="$(U "/discotecas/$($e.DiscoSlug)/")">$(Esc $e.Disco)</a> · Madrid</p>
<dl class="datos">
<dt>Fecha</dt><dd>$(Esc (Cap $fl))</dd>
<dt>Horario</dt><dd>$(Esc $e.Horario)</dd>
<dt>Lugar</dt><dd>$(Esc $e.Disco), Madrid</dd>
</dl>
<a class="btn xl" href="$(U $e.Compra)" rel="nofollow sponsored">Comprar entradas</a>
<p class="nota">Compra segura en Fourvenues, la plataforma oficial de venta del evento.</p>
<p class="texto">$(Esc $e.Titulo) en $(Esc $e.Disco) el $(Esc $fl) de $($e.Fecha.Year). Abre a las $($e.Inicio.ToString('HH:mm')) y dura $finTxt. Consigue tu entrada online para esta fiesta en Madrid: elige tipo de entrada, paga desde el móvil y recibe el QR al momento. Las entradas suelen subir de precio según se acerca el día, así que mejor no esperar.</p>
</div>
</article>
$extra
</div>
<div class="comprar-fija"><a class="btn xl" href="$(U $e.Compra)" rel="nofollow sponsored">Comprar entradas</a></div>
"@
  Guardar $e.Ruta (Pagina -Titulo "$($e.Titulo) en $($e.Disco) – $(Cap $fl) | Entradas" -Desc "Entradas para $($e.Titulo) en $($e.Disco), Madrid. $(Cap $fl), $($e.Horario). Compra tu entrada online." -Ruta $e.Ruta -Cuerpo $cuerpo -JsonLd $ld -Imagen $e.Img -ClaseBody 'con-barra') -Indexar

  # Página puente: el botón "Entradas" apunta a tu dominio y redirige a tu link RRPP
  $dEsc = Esc $destino
  $dJs = $destino.Replace('\', '\\').Replace("'", "\'")
  Guardar $e.Compra @"
<!doctype html>
<html lang="es"><head><meta charset="utf-8">
<meta name="robots" content="noindex, nofollow">
<meta name="referrer" content="no-referrer-when-downgrade">
<meta http-equiv="refresh" content="0; url=$dEsc">
<title>Abriendo la venta de entradas…</title>
<script>location.replace('$dJs');</script>
</head><body style="background:#0a0a10;color:#f4f3f8;font-family:system-ui,sans-serif;text-align:center;padding:40px 16px">
<p>Abriendo la venta de entradas…</p><p><a style="color:#ff2e7e" href="$dEsc">Pulsa aquí si no se abre</a></p>
</body></html>
"@
}

# 404
$cuerpo404 = @"
<div class="wrap hero">
<h1>Esta fiesta ya <em>terminó</em></h1>
<p>La página que buscas no existe o el evento ya pasó. Mira lo que hay hoy y esta semana en Madrid.</p>
<p><a class="btn xl" style="display:inline-block;padding:14px 22px" href="$(U '/')">Ver fiestas de esta semana</a></p>
</div>
"@
Guardar '/404.html' (Pagina -Titulo "Página no encontrada | $Marca" -Desc 'Fiestas en Madrid hoy y esta semana.' -Ruta '/404.html' -Cuerpo $cuerpo404)

# robots.txt y sitemap.xml
Guardar '/robots.txt' "User-agent: *`nDisallow: $Base/entradas/`n`nSitemap: $SiteUrl/sitemap.xml`n"
$hoyIso = $Ahora.ToString('yyyy-MM-dd')
$urls = foreach ($r in $Sitemap) { "<url><loc>$(Esc (Abs $r))</loc><lastmod>$hoyIso</lastmod></url>" }
Guardar '/sitemap.xml' ("<?xml version=`"1.0`" encoding=`"UTF-8`"?>`n<urlset xmlns=`"http://www.sitemaps.org/schemas/sitemap/0.9`">`n" + ($urls -join "`n") + "`n</urlset>`n")

Write-Host "Web generada en $Salida ($($Sitemap.Count) páginas indexables)"
