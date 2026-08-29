# UI strings for the research and software grids.
#
# The site is three separate Quarto projects (root, es/, zh/) rather than a
# Quarto i18n setup, so the language is passed in explicitly by each page.
# Anything missing from a language falls back to English rather than printing
# an empty label.

I18N <- list(
  en = list(
    # --- shell
    unavailable          = "Publication list temporarily unavailable.",
    software_unavailable = "Software list temporarily unavailable.",
    search_placeholder   = "Search title, author, year, journal...",
    search_label         = "Search publications",
    search_software      = "Search name, author, description...",
    search_software_label = "Search software",
    showing              = "Showing {n} of {m}",
    no_matches           = "No items match these filters.",
    clear_filters        = "Clear filters",

    # --- facet group labels
    facet_status = "Status",
    facet_topic  = "Topic",
    facet_venue  = "Venue",
    facet_year   = "Year",
    facet_kind   = "Type",
    facet_lang   = "Language",
    facet_dist   = "Available on",

    # --- facet values
    published = "Published", wip = "Work in progress",
    active = "Active", maintained = "Maintained",
    experimental = "Experimental", archived = "Archived",
    package = "Package", app = "App", library = "Library",
    cli = "CLI", template = "Template",
    dist_cran = "CRAN", dist_pypi = "PyPI", dist_github = "GitHub only",

    # --- sort / view
    sort_by        = "Sort",
    sort_year_desc = "Newest first",
    sort_year_asc  = "Oldest first",
    sort_title     = "Title (A-Z)",
    sort_citations = "Most cited",
    view_label     = "View",
    view_grid      = "Grid",
    view_compact   = "Compact",

    # --- card
    abstract_label       = "Abstract",
    abstract_unavailable = "Abstract unavailable.",
    details              = "Details",
    no_link              = "No external link listed",
    link_publisher       = "Publisher / Preprint",
    untitled             = "Untitled",
    no_date              = "n.d.",

    # --- talks timeline
    talks_summary    = "{n} talks · {span}",
    talks_breakdown  = "{invited} invited · {conference} conference · {other} other",
    talks_unavailable = "Talk list unavailable.",
    jump_to_year     = "Jump to year",
    slides           = "Slides",
    video            = "Video",
    invited_talk           = "Invited talk",
    conference_talk        = "Conference talk",
    conference_poster      = "Poster",
    conference_workshop    = "Conference workshop",
    workshop               = "Workshop",
    talk                   = "Talk",
    months_abb = c("Jan", "Feb", "Mar", "Apr", "May", "Jun",
                   "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"),

    # --- detail pages
    about_label   = "About",
    cite_this     = "Cite",
    copy          = "Copy BibTeX",
    copied        = "Copied",
    related       = "Related",
    back_to_list  = "All research",
    back_to_software = "All software",
    detail_in_english = "(page in English)",
    cited_by         = "Cited by",
    as_of            = "as of",
    cited_via_paper  = "Citations of the companion software paper",
    metrics_note     = "Citation counts from OpenAlex; downloads from CRAN. Updated %s.",

    # --- people page (R/people_page.R)
    people_current     = "Current",
    people_past        = "Past",
    people_present     = "present",
    people_unavailable = "Roster temporarily unavailable."
  ),

  es = list(
    unavailable          = "La lista de publicaciones no está disponible temporalmente.",
    software_unavailable = "La lista de software no está disponible temporalmente.",
    search_placeholder   = "Buscar por título, autor, año, revista...",
    search_label         = "Buscar publicaciones",
    search_software      = "Buscar por nombre, autor, descripción...",
    search_software_label = "Buscar software",
    showing              = "Mostrando {n} de {m}",
    no_matches           = "Ningún elemento coincide con estos filtros.",
    clear_filters        = "Limpiar filtros",

    facet_status = "Estado",
    facet_topic  = "Tema",
    facet_venue  = "Publicación",
    facet_year   = "Año",
    facet_kind   = "Tipo",
    facet_lang   = "Lenguaje",
    facet_dist   = "Disponible en",

    published = "Publicadas", wip = "En progreso",
    active = "Activo", maintained = "Mantenido",
    experimental = "Experimental", archived = "Archivado",
    package = "Paquete", app = "Aplicación", library = "Biblioteca",
    cli = "CLI", template = "Plantilla",
    dist_cran = "CRAN", dist_pypi = "PyPI", dist_github = "Solo GitHub",

    sort_by        = "Ordenar",
    sort_year_desc = "Más recientes",
    sort_year_asc  = "Más antiguas",
    sort_title     = "Título (A-Z)",
    sort_citations = "Más citadas",
    view_label     = "Vista",
    view_grid      = "Cuadrícula",
    view_compact   = "Compacta",

    abstract_label       = "Resumen",
    abstract_unavailable = "Resumen no disponible.",
    details              = "Detalles",
    no_link              = "No hay enlace externo registrado",
    link_publisher       = "Editorial / Preprint",
    untitled             = "Sin título",
    no_date              = "s.f.",

    talks_summary    = "{n} charlas · {span}",
    talks_breakdown  = "{invited} invitadas · {conference} en congresos · {other} otras",
    talks_unavailable = "La lista de charlas no está disponible.",
    jump_to_year     = "Ir al año",
    slides           = "Diapositivas",
    video            = "Video",
    invited_talk           = "Charla invitada",
    conference_talk        = "Charla en congreso",
    conference_poster      = "Póster",
    conference_workshop    = "Taller en congreso",
    workshop               = "Taller",
    talk                   = "Charla",
    months_abb = c("ene", "feb", "mar", "abr", "may", "jun",
                   "jul", "ago", "sep", "oct", "nov", "dic"),

    about_label   = "Acerca de",
    cite_this     = "Citar",
    copy          = "Copiar BibTeX",
    copied        = "Copiado",
    related       = "Relacionado",
    back_to_list  = "Todas las publicaciones",
    back_to_software = "Todo el software",
    detail_in_english = "(página en inglés)",
    cited_by         = "Citado por",
    as_of            = "al",
    cited_via_paper  = "Citas del artículo de software asociado",
    metrics_note     = "Citas de OpenAlex; descargas de CRAN. Actualizado el %s.",

    people_current     = "Actuales",
    people_past        = "Anteriores",
    people_present     = "presente",
    people_unavailable = "Lista de personas temporalmente no disponible."
  ),

  zh = list(
    unavailable          = "出版列表暂时不可用。",
    software_unavailable = "软件列表暂时不可用。",
    search_placeholder   = "按标题、作者、年份、期刊搜索...",
    search_label         = "搜索出版物",
    search_software      = "按名称、作者、描述搜索...",
    search_software_label = "搜索软件",
    showing              = "显示 {m} 项中的 {n} 项",
    no_matches           = "没有符合这些筛选条件的项目。",
    clear_filters        = "清除筛选",

    facet_status = "状态",
    facet_topic  = "主题",
    facet_venue  = "期刊",
    facet_year   = "年份",
    facet_kind   = "类型",
    facet_lang   = "语言",
    facet_dist   = "可获取于",

    published = "已发表", wip = "进行中",
    active = "活跃", maintained = "维护中",
    experimental = "实验性", archived = "已归档",
    package = "软件包", app = "应用", library = "库",
    cli = "命令行工具", template = "模板",
    dist_cran = "CRAN", dist_pypi = "PyPI", dist_github = "仅 GitHub",

    sort_by        = "排序",
    sort_year_desc = "最新优先",
    sort_year_asc  = "最早优先",
    sort_title     = "标题 (A-Z)",
    sort_citations = "引用最多",
    view_label     = "视图",
    view_grid      = "网格",
    view_compact   = "紧凑",

    abstract_label       = "摘要",
    abstract_unavailable = "暂无摘要。",
    details              = "详情",
    no_link              = "暂无外部链接",
    link_publisher       = "期刊 / 预印本",
    untitled             = "无标题",
    no_date              = "无日期",

    talks_summary    = "{n} 場演講 · {span}",
    talks_breakdown  = "{invited} 場受邀演講 · {conference} 場會議演講 · {other} 場其他演講",
    talks_unavailable = "演講列表暫時無法取得。",
    jump_to_year     = "跳至年份",
    slides           = "投影片",
    video            = "影片",
    invited_talk           = "受邀演講",
    conference_talk        = "會議演講",
    conference_poster      = "海報",
    conference_workshop    = "會議工作坊",
    workshop               = "工作坊",
    talk                   = "演講",
    months_abb = c("1月", "2月", "3月", "4月", "5月", "6月",
                   "7月", "8月", "9月", "10月", "11月", "12月"),

    about_label   = "简介",
    cite_this     = "引用",
    copy          = "复制 BibTeX",
    copied        = "已复制",
    related       = "相关内容",
    back_to_list  = "全部研究",
    back_to_software = "全部软件",
    detail_in_english = "（英文页面）",
    cited_by         = "被引用",
    as_of            = "截至",
    cited_via_paper  = "配套软件论文的引用数",
    metrics_note     = "引用数据来自 OpenAlex，下载量来自 CRAN。更新于 %s。",

    people_current     = "現任成員",
    people_past        = "過往成員",
    people_present     = "至今",
    people_unavailable = "名單暫時無法取得。"
  )
)

get_i18n <- function(language = "en") {
  lang <- I18N[[tolower(language)]]
  if (is.null(lang)) return(I18N$en)
  utils::modifyList(I18N$en, lang)   # English fills any gap
}

# Facet values are looked up by their slug; unknown ones (topics, venues,
# years) are shown as-is rather than blanked out.
i18n_value <- function(i18n, value) {
  key <- gsub("-", "_", slugify(value))
  i18n[[key]] %||% value
}

# Backwards-compatible alias: the previous renderers called this.
get_research_i18n <- get_i18n
