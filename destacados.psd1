# Fiestas destacadas: salen en una tira en la portada, en un aviso emergente discreto
# y con su propia página. Desaparecen solas cuando pasa la fecha.
@{
  Destacados = @(
    @{
      Codigo    = 'FNF2'
      Evento    = 'haunted-night-volii-31-10-2026-FNF2'   # final del link de Fourvenues
      Ruta      = '/fiesta-halloween-madrid/'
      Enlace    = 'Fiesta Halloween Madrid'
      Etiqueta  = 'Halloween'
      Emoji     = '🎃'
      Titulo    = 'Haunted Night Vol. II'
      Fecha     = '2026-10-31'
      Inicio    = '00:30'
      Lugar     = 'Finca privada (ubicación secreta)'
      Desde     = 35
      Imagen    = 'https://fourvenues.com/cdn-cgi/imagedelivery/kWuoTchaMsk7Xnc_FNem7A/79ba0786-58a4-4f2a-d91f-b8aef7f38c00/w=1350'
      Gancho    = 'Finca con barra libre y bus desde Madrid'
      Etiquetas = @('+18', 'Disfraz', 'Música comercial')
      Incluye   = @(
        'Barra libre de copas'
        'Autobuses de ida y vuelta desde Moncloa, Ciudad Universitaria, Plaza Castilla y Majadahonda'
        'Finca privada para más de 2.000 personas, con zona interior y exterior'
        'Los mejores DJs del momento'
        'Concurso de disfraces y sorteos con premios'
        'Punching ball, alcoholímetro y robot LED repartiendo chupitos'
        'Foodtruck con comida recién hecha'
      )
      Precios   = @(
        'Entrada con barra libre (sin bus): 35 €'
        'Entrada con barra libre + bus de ida y vuelta: desde 40 €'
      )
      H1        = 'Fiesta de <em>Halloween</em> en Madrid 2026'
      TituloSeo = 'Fiesta Halloween Madrid 2026 en finca con barra libre | Haunted Night'
      DescSeo   = 'Haunted Night Vol. II: la fiesta de Halloween 2026 en Madrid. Finca privada, barra libre de copas, autobuses desde Moncloa, Ciudad Universitaria, Plaza Castilla y Majadahonda. Entradas desde 35 €.'
      Texto     = 'Haunted Night vuelve con su segunda edición la noche de Halloween, el sábado 31 de octubre. Es una fiesta en una finca privada a las afueras de Madrid, con más de 2.000 personas, barra libre de copas durante toda la noche y autobuses lanzadera de ida y vuelta para no preocuparte de cómo volver. Ven disfrazado: hay concurso de disfraces con premios. Las entradas van por tramos y suben de precio según se acerca la fecha, así que cuanto antes la compres, más barata te sale.'
      Popup     = $true
    }
  )

  # Páginas de temporada: reúnen todas las fiestas entre dos fechas. Desaparecen solas al pasar "Hasta".
  # En TituloSeo, Intro y DescSeo, {0} se sustituye por el número de fiestas.
  Especiales = @(
    @{
      Ruta        = '/fiestas-halloween-madrid/'
      Enlace      = 'Fiestas Halloween Madrid 2026'
      Emoji       = '🎃'
      TextoTira   = 'Halloween en Madrid: todas las fiestas'
      Fechas      = 'del 29 de octubre al 1 de noviembre'
      Desde       = '2026-10-29'
      Hasta       = '2026-11-01'
      Imagen      = 'https://fourvenues.com/cdn-cgi/imagedelivery/kWuoTchaMsk7Xnc_FNem7A/79ba0786-58a4-4f2a-d91f-b8aef7f38c00/w=1350'
      Destacado   = 'FNF2'
      H1          = 'Fiestas de <em>Halloween</em> en Madrid 2026'
      TituloSeo   = 'Fiestas Halloween Madrid 2026: {0} fiestas del 29 oct al 1 nov | Fiestas en Madrid'
      Intro       = '{0} fiestas para el puente de Halloween en Madrid, del jueves 29 de octubre al domingo 1 de noviembre: fincas con barra libre, discotecas, tardeos y fiestas de disfraces con entrada online.'
      DescSeo     = 'Todas las fiestas de Halloween 2026 en Madrid: {0} planes del 29 de octubre al 1 de noviembre. Fiestas en finca con barra libre, discotecas y fiestas de disfraces. Compra tus entradas online.'
      TituloTexto = '¿Qué hacer en Halloween 2026 en Madrid?'
      Texto       = 'Halloween 2026 cae en sábado, así que en Madrid se celebra todo el puente: desde el jueves 29 de octubre hasta el domingo 1 de noviembre. La noche fuerte es el sábado 31, con fiestas de disfraces en las principales discotecas de la ciudad y grandes fiestas en fincas a las afueras con barra libre y autobuses desde Madrid. Si buscas un plan de tarde, también hay tardeos temáticos desde las 17:00. Las entradas de Halloween suelen subir de precio por tramos y muchas se agotan los últimos días, así que conviene comprarlas con antelación. Usa el buscador para encontrar tu discoteca o escribe «halloween» para ver solo las fiestas temáticas.'
    }
    @{
      Ruta        = '/fiestas-nochevieja-madrid/'
      Enlace      = 'Fiestas Nochevieja Madrid 2026'
      Emoji       = '🥂'
      TextoTira   = 'Nochevieja en Madrid: todas las fiestas'
      Fechas      = '31 de diciembre y 1 de enero'
      Desde       = '2026-12-31'
      Hasta       = '2027-01-01'
      Imagen      = 'https://fourvenues.com/cdn-cgi/imagedelivery/kWuoTchaMsk7Xnc_FNem7A/988999fa-b7b7-437b-78d8-3a6e830d0700/width=534'
      Destacado   = ''
      H1          = 'Fiestas de <em>Nochevieja</em> en Madrid 2026'
      TituloSeo   = 'Fiestas Nochevieja Madrid 2026-2027: {0} fiestas y entradas | Fiestas en Madrid'
      Intro       = '{0} fiestas para despedir 2026 en Madrid: Nochevieja en las mejores discotecas después de las campanadas y planes para el día de Año Nuevo, con entrada online.'
      DescSeo     = 'Todas las fiestas de Nochevieja 2026 en Madrid: {0} planes para el 31 de diciembre y Año Nuevo en Fitz, Vandido, Joy Eslava, Teatro Magno, Florida Park y más. Compra tus entradas online.'
      TituloTexto = '¿Dónde celebrar la Nochevieja 2026 en Madrid?'
      Texto       = 'La Nochevieja de 2026 cae en jueves y en Madrid la fiesta empieza justo después de las campanadas: la mayoría de discotecas abren entre las 00:30 y la 1:00 y cierran a las 6:00 o incluso a las 8:00 de la mañana. Hay planes para todos los gustos: grandes salas como Teatro Magno o Florida Park, discotecas como Fitz, Vandido, Joy Eslava o Tiffany''s, y fiestas latinas y de reguetón. Es la noche con las entradas más caras y que antes se agotan del año, y muchas suben de precio por tramos, así que conviene reservar con antelación. Si prefieres seguir de fiesta, el 1 de enero también hay planes desde la tarde.'
    }
  )
}
