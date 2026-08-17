knitr::opts_chunk$set(echo = TRUE, warning = FALSE, message = FALSE)
suppressMessages(suppressWarnings({
  library(jsonlite)
  library(ggplot2)
  library(dplyr)
  library(readxl)
}))

metadata <- fromJSON('metadatos.json')

as_chr_vec <- function(x) {
  if (is.null(x)) character(0) else as.character(x)
}

value_or_empty <- function(x, i) {
  if (length(x) >= i) as.character(x[i]) else ""
}

format_apa_authors <- function(authors) {
  authors <- as_chr_vec(authors)
  if (!length(authors)) return("")

  formatted <- sapply(authors, function(name) {
    parts <- strsplit(trimws(name), "\\s+")[[1]]
    if (length(parts) == 1) return(parts)
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

title_sp <- value_or_empty(metadata$title_sp, 1)
title_en <- value_or_empty(metadata$title_en, 1)
abstract_sp <- value_or_empty(metadata$abstract_sp, 1)
abstract_en <- value_or_empty(metadata$abstract_en, 1)
keywords_sp <- as_chr_vec(metadata$keywords_sp)
keywords_en <- as_chr_vec(metadata$keywords_en)
authors_name <- as_chr_vec(metadata$authors_name)
authors_affiliation <- as_chr_vec(metadata$authors_affiliation)
authors_orcid <- as_chr_vec(metadata$authors_orcid)
authors_email <- as_chr_vec(metadata$authors_email)
volume <- value_or_empty(metadata$source_volume, 1)
issue <- value_or_empty(metadata$source_issue, 1)
pages <- value_or_empty(metadata$pages, 1)
date_created <- value_or_empty(metadata$date_created, 1)
date_issued <- value_or_empty(metadata$date_issued, 1)
logo_path <- normalizePath(file.path("..", "template", "logo-violeta-horizontal.png"), winslash = "/", mustWork = TRUE)
logo_uri <- paste0("file:///", logo_path)
source_issn <- value_or_empty(metadata$source_issn, 1)
section_raw <- value_or_empty(metadata$section, 1)

section_label <- function(x) {
  key <- tolower(trimws(x))
  switch(key,
    "editorial" = "Editorial",
    "desarrollos" = "Desarrollos",
    "articulos" = "Artículos",
    "artículos" = "Artículos",
    "aprendizajes" = "Enseñanza y Aprendizaje",
    "articulos de investigacion" = "Artículos de investigación",
    "artículos de investigación" = "Artículos de investigación",
    if (nzchar(x)) x else ""
  )
}

first_author <- if (length(authors_name)) tail(strsplit(authors_name[1], "\\s+")[[1]], 1) else "DCSC"
short_title <- if (nchar(title_sp) > 48) paste0(substr(title_sp, 1, 45), "...") else title_sp
print_top_left <- if (length(authors_name) > 1) {
  paste0(first_author, " et al. (", substr(date_created, 1, 4), ") · ", short_title)
} else {
  paste0(first_author, " (", substr(date_created, 1, 4), ") · ", short_title)
}
print_top_right <- paste0("DCSC · Vol. ", volume, " (", issue, ") · ", pages)

estilos <- "
<style>
@page { size: A4; margin: 14mm 16mm 16mm; }
@page:first { margin: 0; }

html { background: #f4f2f7; }
<<PRINT_VARS>>
body {
  margin: 0 !important;
  padding: 0 !important;
  max-width: none !important;
  background: #f4f2f7;
  color: #1f1f26;
  font-family: 'Fira Sans Condensed', Arial, sans-serif;
  text-align: justify;
  line-height: 1.5;
}

h1.title, h1.title.toc-ignore { display: none !important; }
#refs { text-align: left; }

.article-front {
  width: min(100%, 1120px);
  margin: 0 auto 32px;
  background: #fff;
  box-shadow: 0 8px 34px rgba(29, 12, 51, 0.12);
  color: #1f1f26;
  text-align: left;
}

.journal-header {
  background: #311955;
  min-height: 154px;
  display: flex;
  align-items: center;
}

.journal-header-inner {
  width: 100%;
  padding: 26px 7.5%;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 32px;
  box-sizing: border-box;
}

.journal-brand {
  min-width: 0;
  flex: 1 1 auto;
  display: flex;
  align-items: center;
}

.journal-logo {
  display: block;
  max-width: 560px;
  width: min(100%, 560px);
  max-height: 94px;
  object-fit: contain;
  object-position: left center;
}

.issue-meta {
  flex: 0 0 auto;
  padding-left: 26px;
  color: #fff;
  font-size: 1.18rem;
  font-weight: 400;
  letter-spacing: 0;
  white-space: nowrap;
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: .15em;
  line-height: 1;
}

.issue-volume {
  white-space: nowrap;
}

.issue-issn {
  font-size: .72em;
  letter-spacing: .02em;
  opacity: .92;
}

.issue-dot { display: none; }

.front-content {
  padding: 40px 8% 28px;
}

.title-block { margin-bottom: 28px; }
.article-title {
  margin: 0;
  max-width: 960px;
  color: #311955 !important;
  font-family: 'Fira Sans Condensed', Arial, sans-serif !important;
  font-size: clamp(2.2rem, 4.7vw, 3.35rem) !important;
  line-height: .98 !important;
  font-weight: 700 !important;
  letter-spacing: -.018em;
  text-align: left;
}

.article-title-en {
  margin-top: 15px;
  max-width: 900px;
  color: #666675;
  font-size: clamp(1.25rem, 2.5vw, 1.78rem);
  line-height: 1.12;
  font-weight: 400;
}

.title-accent {
  width: 72px;
  height: 3px;
  background: #311955;
  margin-top: 24px;
}

.authors-grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: 16px;
  padding-bottom: 26px;
  border-bottom: 2px solid #311955;
}

.author-card { min-width: 0; }
.author-name {
  color: #17171d;
  font-size: 1.18rem;
  line-height: 1.12;
  font-weight: 700;
}
.author-affiliation {
  margin-top: 2px;
  color: #30303a;
  font-size: .98rem;
  line-height: 1.2;
}
.author-links {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 7px 12px;
  margin-top: 5px;
  font-size: .94rem;
  line-height: 1.15;
}
.contact-link {
  display: inline-flex;
  align-items: center;
  gap: 7px;
  color: #311955 !important;
  text-decoration: none !important;
  min-width: 0;
}
.contact-link:hover span { text-decoration: underline; }
.contact-icon {
  width: 19px;
  height: 19px;
  flex: 0 0 19px;
  display: inline-block;
}
.mail-icon { color: #311955; }
.contact-divider {
  display: inline-block;
  width: 1px;
  height: 16px;
  background: #77717f;
  margin: 0 2px;
}

.abstract-grid {
  display: grid;
  grid-template-columns: minmax(0, 1fr) minmax(0, 1fr);
  gap: 0;
  padding: 22px 0 20px;
  border-bottom: 2px solid #7440cc;
}
.abstract-column {
  padding-right: 30px;
  min-width: 0;
}
.abstract-column-en {
  padding-right: 0;
  padding-left: 30px;
  border-left: 1px solid #cfc5dc;
}
.front-section-title {
  margin: 0 0 10px !important;
  color: #5d20b8 !important;
  font-family: 'Fira Sans Condensed', Arial, sans-serif !important;
  font-size: 1.12rem !important;
  line-height: 1 !important;
  font-weight: 700 !important;
  text-transform: uppercase;
  letter-spacing: .01em;
}
.abstract-column p {
  margin: 0 0 12px;
  color: #26262d;
  font-size: .94rem;
  line-height: 1.18;
  text-align: justify;
  hyphens: auto;
}
.abstract-column .keywords {
  margin-top: 16px;
  margin-bottom: 0;
  font-size: .94rem;
  line-height: 1.16;
  text-align: left;
}
.abstract-column .keywords strong { color: #311955; }

.extra-data-table {
  width: 100%;
  border-collapse: collapse;
  margin-top: 14px;
  margin-bottom: 6px;
  font-size: .93rem;
}

.data-header {
  width: 34%;
  border: 1px solid #d8d0e4;
  padding: 8px 10px;
  text-align: right;
  background: #f8f6fb;
  color: #311955;
  font-weight: 700;
  vertical-align: top;
}

.data-content {
  border: 1px solid #d8d0e4;
  padding: 8px 10px;
  background: #fff;
  vertical-align: top;
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
  color: #311955;
  font-size: 0.85em;
  font-weight: 600;
  text-align: center;
  border: 1px solid #d0d7de;
}

.front-footer { font-size: .96rem; }
.dates-row {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 18px;
  padding: 12px 0;
  border-bottom: 1px solid #7440cc;
  color: #282832;
}
.dates-row strong, .citation-row strong { color: #311955; }
.date-divider {
  display: inline-block;
  height: 17px;
  width: 1px;
  background: #7a737e;
}
.citation-row {
  padding-top: 13px;
  color: #24242c;
  line-height: 1.24;
  text-align: left;
}

  .license-row {
    padding-top: 8px;
    color: #24242c;
    line-height: 1.18;
    text-align: left;
    font-size: .92em;
  }

  .license-row.is-hidden {
    display: none;
  }

.article-front::after {
  content: '';
  display: block;
  height: 10px;
  background: #311955;
  margin-top: 24px;
}

.article-body {
  box-sizing: border-box;
  width: min(100% - 32px, 1040px);
  margin: 0 auto 50px;
  padding: 38px 56px 58px;
  background: #fff;
  box-shadow: 0 8px 34px rgba(29, 12, 51, 0.08);
  color: #303038;
}
.article-body h2 {
  color: #311955 !important;
  font-size: 1.8rem !important;
  line-height: 1.08 !important;
  margin-top: 1.65em !important;
  margin-bottom: .7em !important;
  padding-bottom: .18em;
  border-bottom: 1px solid #d7cae8;
}
.article-body a { color: #311955; }
.article-body img { max-width: 100%; height: auto; }
.article-body table { max-width: 100%; }

@media screen and (max-width: 760px) {
  .journal-header { min-height: 120px; }
  .journal-header-inner { padding: 22px 6%; gap: 18px; }
  .journal-logo { max-height: 72px; }
  .issue-meta { padding-left: 18px; font-size: 1.05rem; }
  .front-content { padding: 30px 6% 22px; }
  .article-title { font-size: 2.25rem !important; }
  .abstract-grid { grid-template-columns: 1fr; }
  .abstract-column { padding-right: 0; }
  .abstract-column-en { border-left: 0; border-top: 1px solid #d8cede; padding: 22px 0 0; margin-top: 8px; }
  .article-body { width: calc(100% - 20px); padding: 28px 22px 42px; }
}

@media print {
  @page {
    size: A4;
    margin: 22mm 18mm 20mm 18mm;

    @top-left {
      content: var(--print-top-left);
      font-family: Arial, sans-serif;
      font-size: 8pt;
      color: #777;
    }

    @top-right {
      content: var(--print-top-right);
      font-family: Arial, sans-serif;
      font-size: 8pt;
      color: #6f2dbd;
    }

    @bottom-right {
      content: counter(page);
      font-family: Arial, sans-serif;
      font-size: 8pt;
      color: #777;
    }
  }

  @page :first {
    margin: 0;

    @top-left { content: none; }
    @top-right { content: none; }
    @bottom-right { content: none; }
  }

  html, body { background: #fff !important; }
  body { print-color-adjust: exact; -webkit-print-color-adjust: exact; }
  .article-front {
    width: 210mm;
    min-height: 297mm;
    margin: 0;
    box-shadow: none;
    page-break-after: always;
    break-after: page;
    overflow: hidden;
  }
  .journal-header { min-height: 40mm; }
  .journal-header-inner { padding: 7mm 16mm; }
  .journal-logo { max-width: 112mm; max-height: 25mm; }
  .issue-meta { font-size: 11pt; padding-left: 8mm; }
  .issue-issn { font-size: 7.5pt; }
  .issue-issn { font-size: 7.8pt; }
  .front-content { padding: 9mm 17mm 4mm; }
  .title-block { margin-bottom: 5.2mm; }
  .article-title {
    font-size: 27pt !important;
    line-height: .96 !important;
    max-width: none;
  }
  .article-title-en {
    font-size: 13.6pt;
    line-height: 1.08;
    margin-top: 3.4mm;
    max-width: none;
  }
  .title-accent { width: 18mm; height: .7mm; margin-top: 5mm; }
  .authors-grid { gap: 3.2mm; padding-bottom: 4.8mm; }
  .author-name { font-size: 10.7pt; }
  .author-affiliation { font-size: 9.1pt; }
  .author-links { font-size: 8.7pt; margin-top: 1mm; gap: 1.5mm 2.4mm; }
  .contact-icon { width: 4.2mm; height: 4.2mm; flex-basis: 4.2mm; }
  .contact-divider { height: 3.5mm; }
  .abstract-grid {
    display: grid !important;
    grid-template-columns: minmax(0, 1fr) minmax(0, 1fr) !important;
    gap: 0 !important;
    padding: 4.3mm 0 3.7mm;
    break-inside: avoid;
    page-break-inside: avoid;
  }
  .abstract-column {
    min-width: 0;
    padding-right: 6mm !important;
  }
  .abstract-column-en {
    padding: 0 0 0 6mm !important;
    margin-top: 0 !important;
    border-top: 0 !important;
    border-left: 1px solid #cfc5dc !important;
  }
  .front-section-title { font-size: 10pt !important; margin-bottom: 2mm !important; }
  .abstract-column p { font-size: 8.15pt; line-height: 1.08; margin-bottom: 2.2mm; }
  .abstract-column .keywords { font-size: 8.15pt; line-height: 1.07; margin-top: 2.5mm; }
  .extra-data-table { margin-top: 3.5mm; font-size: 8.15pt; }
  .data-header, .data-content { padding: 1.8mm 2.2mm; }
  .front-footer { font-size: 8.6pt; }
  .dates-row { padding: 2.6mm 0; gap: 4mm; }
  .citation-row { padding-top: 2.5mm; line-height: 1.13; }
  .license-row { padding-top: 1.8mm; line-height: 1.1; }
  .article-front::after { height: 2.2mm; margin-top: 4mm; }
  .article-body {
    width: auto;
    margin: 0;
    padding: 0;
    box-shadow: none;
  }
  .article-body h2 { break-after: avoid-page; page-break-after: avoid; }
  a { color: inherit; text-decoration: none; }
}
</style>
"

print_vars <- paste0(
  ":root { --print-top-left: \"",
  gsub('"', "'", print_top_left, fixed = TRUE),
  "\"; --print-top-right: \"",
  gsub('"', "'", print_top_right, fixed = TRUE),
  "\"; }"
)
estilos <- sub("<<PRINT_VARS>>", print_vars, estilos, fixed = TRUE)

cat('<link href="https://fonts.googleapis.com/css2?family=Fira+Sans+Condensed:wght@300;400;600;700&display=swap" rel="stylesheet">',
    estilos, file = "custom-head.html")

cat('<section class="article-front" aria-labelledby="article-title">')
cat('<header class="journal-header">')
cat('<div class="journal-header-inner">')
cat('<div class="journal-brand">')
cat('<img src="', logo_uri, '" alt="', metadata$source, '" class="journal-logo" />', sep = "")
cat('</div>')
cat('<div class="issue-meta" aria-label="Datos del número">')
cat('<span class="issue-volume">Vol. ', volume, ' (', issue, ') · ', pages, '</span>', sep = "")
if (nzchar(trimws(source_issn))) {
  cat('<span class="issue-issn">ISSN ', source_issn, '</span>', sep = "")
}
cat('</div>')
cat('</div>')
cat('</header>')

cat('<div class="front-content">')
cat('<div class="title-block">')
cat('<h1 id="article-title" class="article-title">', title_sp, '</h1>', sep = "")
if (nzchar(trimws(title_en))) {
  cat('<div class="article-title-en" lang="en">', title_en, '</div>', sep = "")
}
cat('<div class="title-accent" aria-hidden="true"></div>')
cat('</div>')

cat('<section class="authors-grid" aria-label="Autores">')
for (i in seq_along(authors_name)) {
  cat('<div class="author-card">')
  cat('<div class="author-name">', value_or_empty(authors_name, i), '</div>', sep = "")
  cat('<div class="author-affiliation">', value_or_empty(authors_affiliation, i), '</div>', sep = "")
  cat('<div class="author-links">')
  email <- value_or_empty(authors_email, i)
  orcid <- value_or_empty(authors_orcid, i)
  if (nzchar(email)) {
    cat('<a href="mailto:', email, '" class="contact-link email-link">',
        '<svg class="contact-icon mail-icon" viewBox="0 0 24 24" aria-hidden="true"><path d="M3.5 5.5h17v13h-17z" fill="none" stroke="currentColor" stroke-width="1.8"/><path d="m4.5 7 7.5 6 7.5-6" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/></svg>',
        '<span>', email, '</span></a>', sep = "")
  }
  if (nzchar(email) && nzchar(orcid)) cat('<span class="contact-divider" aria-hidden="true"></span>')
  if (nzchar(orcid)) {
    cat('<a href="', orcid, '" target="_blank" rel="noopener" class="contact-link orcid-link">',
        '<svg class="contact-icon orcid-icon" viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="11" fill="#A6CE39"/><text x="12" y="15.2" text-anchor="middle" font-family="Arial, sans-serif" font-weight="700" font-size="9.5" fill="#fff">iD</text></svg>',
        '<span>', orcid, '</span></a>', sep = "")
  }
  cat('</div>')
  cat('</div>')
}
cat('</section>')

cat('<section class="abstract-grid" aria-label="Resumen y abstract">')
cat('<div class="abstract-column">')
cat('<h2 class="front-section-title">Resumen</h2>')
cat('<p>', abstract_sp, '</p>', sep = "")
cat('<p class="keywords"><strong>Palabras clave:</strong> ', paste(keywords_sp, collapse = ', '), '</p>', sep = "")
cat('</div>')
cat('<div class="abstract-column abstract-column-en" lang="en">')
cat('<h2 class="front-section-title">Abstract</h2>')
cat('<p>', abstract_en, '</p>', sep = "")
cat('<p class="keywords"><strong>Keywords:</strong> ', paste(keywords_en, collapse = ', '), '</p>', sep = "")
cat('</div>')
cat('</section>')

url_fields <- list(
  list(label = "Repositorio/Repository", url = value_or_empty(metadata$repository_url, 1)),
  list(label = "Archivo/Archive", url = value_or_empty(metadata$archive_url, 1)),
  list(label = "Documentación", url = value_or_empty(metadata$documentation_url, 1)),
  list(label = "Vignette", url = value_or_empty(metadata$vignette_url, 1)),
  list(label = "Demo", url = value_or_empty(metadata$demo_url, 1)),
  list(label = "Licencia/Licence", url = value_or_empty(metadata$licence_url, 1)),
  list(label = "Website", url = value_or_empty(metadata$website_url, 1))
)
url_fields <- Filter(function(f) nzchar(trimws(f$url)), url_fields)

tech <- if (!is.null(metadata$techonologies)) as_chr_vec(metadata$techonologies) else character(0)
if (!length(tech) && !is.null(metadata$technologies)) tech <- as_chr_vec(metadata$technologies)

if (length(url_fields) > 0 || length(tech) > 0) {
  cat('<table class="extra-data-table">')
  for (f in url_fields) {
    cat('<tr><td class="data-header">', f$label, '</td><td class="data-content"><a href="', f$url, '" target="_blank" rel="noopener">', f$url, '</a></td></tr>', sep = "")
  }
  if (length(tech) > 0) {
    cat('<tr><td class="data-header">Lenguajes/Formatos</td><td class="data-content"><div class="tag-list">')
    for (t in tech) {
      if (nzchar(trimws(t))) cat('<div class="tag">', t, '</div>', sep = "")
    }
    cat('</div></td></tr>')
  }
  cat('</table>')
}

cat('<footer class="front-footer">')
cat('<div class="dates-row">')
cat('<span><strong>Recibido:</strong> ', date_created, '</span>', sep = "")
cat('<span class="date-divider" aria-hidden="true"></span>')
cat('<span><strong>Aceptado:</strong> ', date_issued, '</span>', sep = "")
if (nzchar(trimws(section_label(section_raw)))) {
  cat('<span class="date-divider" aria-hidden="true"></span>')
  cat('<span><strong>Sección:</strong> ', section_label(section_raw), '</span>', sep = "")
}
cat('</div>')
cat('<div class="citation-row"><strong>Cita APA:</strong> ',
    format_apa_authors(authors_name), ' (', substr(date_created, 1, 4), '). ',
    title_sp, '. <i>', metadata$source, '</i> ',
    volume, ' (', issue, '), ', pages,
    '</div>', sep = "")
if (tolower(trimws(section_raw)) != "desarrollos") {
  cat('<div class="license-row"><strong>Licencia:</strong> Creative Commons Atribución-NoComercial-SinDerivadas 4.0 Internacional (CC BY-NC-ND 4.0)</div>')
}
cat('</footer>')
cat('</div>')
cat('</section>')
cat('<main class="article-body">')
