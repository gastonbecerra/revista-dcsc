knitr::opts_chunk$set(echo = TRUE, warning = FALSE, message = FALSE)
suppressMessages(suppressWarnings({
  library(jsonlite)
  library(ggplot2)
  library(dplyr)
  library(readxl)
}))

metadata <- fromJSON('metadatos.json')

# estilos ------

estilos <- "
<style>
body {
  font-family: 'Fira Sans Condensed', sans-serif;
  font-weight: 400;
  color: #333;
  line-height: 1.6;
  margin: 20px auto;
  padding: 10px;
  max-width: 1200px;
}

h1.title {
    display: none;
}

.encabezado {
  display: flex;
  align-items: center;
  border-bottom: 2px solid #B8BCC2;
  padding-bottom: 10px;
  margin-bottom: 20px;
}

.encabezado img {
  height: 80px;
  margin-right: 20px;
}

.encabezado h1 {
  line-height: 90%;
}

h1, h2 {
  color: #9237E2;
  font-family: 'Fira Sans Condensed', sans-serif;
  font-weight: 700;
}

h1 {
  font-size: 2.5em;
  margin: 0;
}

h2 {
  font-size: 1.9em;
  margin-top: 20px;
  margin-bottom: 10px;
}

.encabezado p {
  margin: 5px 0;
  color: #666;
  font-family: 'Fira Sans Condensed', sans-serif;
  font-weight: 400;
}

footer {
  text-align: center;
  font-size: 0.9em;
  margin-top: 40px;
  color: #666;
}

h1.titulo-es {
  font-weight: bold;
  color: #9237E2;
  line-height: 95%;
}

h2.titulo-en {
  font-weight: 400;
  font-size: 1.7em;
  color: #9237E2;
  margin-top: 5px;
  line-height: 95%;
}

.tag-list {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.tag {
  padding: 4px 8px;
  border-radius: 12px;
  background-color: #eef2ff;
  color: #3366cc;
  font-size: 0.85em;
  font-weight: 600;
  text-align: center;
  border: 1px solid #d0d7de;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.1);
  transition: background-color 0.2s, color 0.2s;
}

.data-header {
  border: 1px solid #ddd;
  padding: 8px;
  text-align: right
}

.data-content {
  border: 1px solid #ddd;
  padding: 8px;
}

.abstract {
  font-size: 1em;
  color: #333;
  text-align: center;
  font-style: italic;
  line-height: 95%;
  min-width: 500px;
  max-width: 800px;
  margin: 12px auto 12px auto;
}
.authors {
  text-align: center;
  font-size: 1em;
  color: #333;
}
.cita {
  font-size: 1em;
  color: #333;
  text-align: center;
  line-height: 95%;
  min-width: 500px;
  max-width: 800px;
  margin: 12px auto 12px auto;
}


footer {
   text-align: center;
   font-size: 0.9em;
   margin-top: 40px;
   color: #666;
}
</style>
"

# metadatos -----

cat('
<title>', metadata$title_sp, ' | DCSC</title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<meta name="description" content="', metadata$abstract_sp, '" />
<meta name="keywords" content="', paste(metadata$keywords_sp, collapse = ', '), '" />
<meta name="DC.Language" content="', paste(metadata$language, collapse = ', '), '" />
<meta name="DC.Type" content="', metadata$type, '" />
<meta name="DC.Format" content="', paste(metadata$format, collapse = ', '), '" />
<meta name="DC.Creator.PersonalName" content="', paste(metadata$authors_name, collapse = '"/><meta name="DC.Creator.PersonalName" content="'), '" />
<meta name="DC.Creator.Affiliation" content="', paste(metadata$authors_affiliation, collapse = '"/><meta name="DC.Creator.Affiliation" content="'), '" />
<meta name="DC.Creator.ORCID" content="', paste(metadata$authors_orcid, collapse = '"/><meta name="DC.Creator.ORCID" content="'), '" />
<meta name="DC.Creator.Email" content="', paste(metadata$authors_email, collapse = '"/><meta name="DC.Creator.Email" content="'), '" />
<meta name="DC.Identifier" content="', metadata$identifier, '" />
<meta name="DC.Identifier.URI" content="', metadata$identifier_uri, '" />
<meta name="DC.Source" content="', metadata$source, '" />
<meta name="DC.Source.Volume" content="', metadata$source_volume, '" />
<meta name="DC.Source.Issue" content="', metadata$source_issue, '" />
<meta name="DC.Source.ISSN" content="', metadata$source_issn, '" />
<meta name="DC.Date.Created" content="', metadata$date_created, '" />
<meta name="DC.Date.Issued" content="', metadata$date_issued, '" />
<meta name="DC.Date.Modified" content="', metadata$date_modified, '" />
<meta name="DC.Publisher" content="', metadata$publisher, '" />
<meta name="DC.Format.extent" content="', metadata$publisher, '" />
<meta name="DC.Subject" content="', if (!is.null(metadata$section)) metadata$section else '', '" />

<link href="https://fonts.googleapis.com/css2?family=Fira+Sans+Condensed:wght@300;400;600;700&display=swap" rel="stylesheet">',
estilos, file = "custom-head.html")

# encabezado -----

cat('<div style="margin-bottom: 20px;">')

cat('<div style="display: flex; align-items: flex-start; margin-bottom: 20px;">')
cat('<img src="../../template/logo-blanco.jpg" alt="Logo Revista" style="height: 175px; margin-right: 20px;">')
cat('<div>')
cat('<p style="margin: 20px 0px; color: #666;">Revista <strong>', metadata$source, '</strong> Vol. ', metadata$source_volume, ' (', metadata$source_issue, '), ', metadata$pages, '</p>', sep = "")
cat('<h1 class="titulo-es" style="font-size: 1.8em; margin: 10px 0; color: #9237E2;">', metadata$title_sp, '</h1>')
cat('<h2 class="titulo-en" style="font-size: 1.4em; margin: 0; color: #666;">', metadata$title_en, '</h2>')
cat('</div>')
cat('</div>')

cat('</div>')

# Autores con datos
for (i in seq_along(metadata$authors_name)) {
  cat('<p class="authors">',
      metadata$authors_name[i], 
      ' (', metadata$authors_affiliation[i], ') <br/>', 
      metadata$authors_email[i] , ' ',
      '<a href="', metadata$authors_orcid[i], '" target="_blank">', metadata$authors_orcid[i], '</a>',
      '</p>', sep = "")
}

# Abstract y keywords en español
cat('<p class="abstract"><strong>Resumen:</strong> ', 
    metadata$abstract_sp, '</p>')
cat('<p class="abstract"><strong>Palabras clave:</strong> ', 
    paste(metadata$keywords_sp, collapse = ", "), '</p>')

cat('<p class="abstract"><strong>Abstract:</strong> ', 
    metadata$abstract_en, '</p>')
cat('<p class="abstract"><strong>Keywords:</strong> ', 
    paste(metadata$keywords_en, collapse = ", "), '</p>')

cat('<p class="abstract"><strong>Recibido:</strong> ', 
    metadata$date_created, 
    ' | <strong>Aceptado:</strong> ', 
    metadata$date_issued, '</p>')

# Cita APA
format_apa_authors <- function(authors) {
  formatted <- sapply(authors, function(name) {
    parts <- strsplit(name, " ")[[1]]
    last_name <- tail(parts, 1)
    initials <- paste(substr(parts[-length(parts)], 1, 1), collapse = ". ")
    paste(last_name, paste0(initials, "."))
  })
  if (length(formatted) > 1) {
    paste(paste(formatted[-length(formatted)], collapse = ", "), "&", formatted[length(formatted)])
  } else {
    formatted
  }
}

cat('<p class="cita"><strong>Cita APA:</strong> ', 
    format_apa_authors(metadata$authors_name), ' (',
    substr(metadata$date_created, 1, 4), '). ', 
    metadata$title_sp, '. ', '<i>', metadata$source, '</i> ', 
    metadata$source_volume, ' (', metadata$source_issue, ')',
    ', ', metadata$pages, 
    '</p>', sep = "")

# Tabla de URLs (solo si hay URLs definidas)
has_urls <- function(x) !is.null(x) && length(x) > 0 && any(nchar(trimws(x)) > 0, na.rm = TRUE) && !any(tolower(trimws(x)) %in% c("missing", "na", "n/a"))

url_fields <- list(
  list(label = "Repositorio/Repository",  url = metadata$repository_url),
  list(label = "Archivo/Archive",         url = metadata$archive_url),
  list(label = "Documentación",           url = metadata$documentation_url),
  list(label = "Vignette",                url = metadata$vignette_url),
  list(label = "Demo",                    url = metadata$demo_url),
  list(label = "Licencia/Licence",        url = metadata$licence_url),
  list(label = "Website",                 url = metadata$website_url)
)
url_fields <- url_fields[sapply(url_fields, function(f) has_urls(f$url))]

if (length(url_fields) > 0) {
  cat('<table style="width: 100%; border-collapse: collapse; margin-top: 10px;">')
  cat('<tr style="background-color: #f2f2f2; text-align: left;">',
      '<th class="data-header">Recurso/Resources</th>',
      '<th class="data-content">URL</th></tr>')
  for (f in url_fields) {
    cat('<tr>',
        '<td class="data-header">', f$label, '</td>',
        '<td class="data-content"><a href="', f$url, '" target="_blank">', f$url, '</a></td>',
        '</tr>')
  }

  tech <- if (!is.null(metadata$techonologies)) metadata$techonologies
          else if (!is.null(metadata$technologies)) metadata$technologies
          else NULL

  if (!is.null(tech) && length(tech) > 0 && any(nchar(tech) > 0)) {
    cat('<tr>',
        '<td class="data-header">Lenguajes/Languages Formatos/Formats</td>',
        '<td class="data-content">')
    cat('<div class="tag-list">')
    for (t in tech) {
      if (nchar(t) > 0) cat('<div class="tag">', t, '</div>')
    }
    cat('</div>')
    cat('</td></tr>')
  }
  cat('</table>')
}


