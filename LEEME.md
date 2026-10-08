# Fiestas en Madrid

Web de fiestas en Madrid que se actualiza sola cada día. Todos los botones de «Entradas» llevan a tu link de RRPP de Fourvenues.

## Qué hay en esta carpeta

| Archivo | Para qué sirve |
|---|---|
| `fiestas.tsv` | Las fiestas (si usas Google Sheets, se descarga de ahí cada mañana) |
| `generar.ps1` | Crea la web completa en la carpeta `public/` |
| `estatico/` | Diseño (`estilos.css`) y buscador (`app.js`) |
| `marcador.html` | Botón «📋 Copiar fiestas» para sacar las fiestas de Fourvenues en un clic |
| `.github/workflows/actualizar.yml` | Actualiza y publica la web cada día a las 7:00 |
| `rrpp.txt` | Tu link de RRPP (solo en tu ordenador; **no se sube a GitHub**) |
| `servidor.ps1` | Para ver la web en tu ordenador: http://localhost:8080 |

## Publicarla (una sola vez, unos 20 minutos)

1. **Dominio**: compra uno (`fiestasenmadrid.com`, comprado) en Namecheap, Cloudflare o Porkbun, con la **privacidad WHOIS activada**.
2. **GitHub**: crea una cuenta con un email nuevo, sin tu nombre real. Crea un repositorio y sube todos los archivos de esta carpeta **excepto `rrpp.txt` y `public/`**.
3. En el repositorio, ve a **Settings › Secrets and variables › Actions**:
   - En **Secrets**, crea `RRPP_URL` = tu link de RRPP (el que está en `rrpp.txt`)
   - En **Variables**, crea `SITE_URL` = `https://fiestasenmadrid.com`
   - Opcional: en **Variables**, crea `SHEET_TSV_URL` (ver la sección de abajo)
4. **Settings › Pages › Source**: elige «GitHub Actions». En «Custom domain», escribe tu dominio y sigue los pasos de DNS que te indica.
5. **Actions › Actualizar web de fiestas › Run workflow**. En 1–2 minutos la web está en línea.

## Actualizar las fiestas

**Opción A: Google Sheets (recomendada)**
1. Crea una hoja de Google. Selecciona todo y ve a **Formato › Número › Texto sin formato**, para que Google no cambie las fechas ni los códigos.
2. **Archivo › Compartir › Publicar en la web** › elige la hoja › formato **«Valores separados por tabuladores (.tsv)»** › Publicar. Copia el enlace y pégalo en la variable `SHEET_TSV_URL`.
3. Cuando salgan fiestas nuevas: en Fourvenues pulsa «Ver todos los eventos», luego **📋 Copiar fiestas**, y pega en la celda A1 de la hoja.

**Opción B: sin hoja.** Edita `fiestas.tsv` directamente en GitHub y guarda los cambios.

La web se regenera sola cada mañana: las fiestas pasadas desaparecen y las páginas «hoy» y «finde» se actualizan.

## Google (SEO)

1. Entra en [Google Search Console](https://search.google.com/search-console), añade tu dominio y verifícalo.
2. En **Sitemaps**, envía `https://fiestasenmadrid.com/sitemap.xml`.
3. Pon el link de la web en la bio de Instagram y en TikTok. Los enlaces de otras webs y redes ayudan a posicionar.
