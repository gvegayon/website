fetch_github_badges <- function(owner, repo) {
  urls_to_try <- c(
    sprintf("https://raw.githubusercontent.com/%s/%s/main/README.md", owner, repo),
    sprintf("https://raw.githubusercontent.com/%s/%s/master/README.md", owner, repo)
  )
  
  ans <- character(0)
  for (u in urls_to_try) {
    res <- tryCatch({
      suppressWarnings(readLines(u, warn = FALSE))
    }, error = function(e) character(0))
    if (length(res) > 0) {
      ans <- res
      break
    }
  }
  
  if (length(ans) == 0) return("")
  
  txt <- paste(ans[1:min(50, length(ans))], collapse = "\n")
  
  pattern <- "(?i)\\[\\!\\[([^\\]]*)\\]\\(([^)]+)\\)\\]\\(([^)]+)\\)"
  m <- gregexpr(pattern, txt, perl = TRUE)
  
  badges_html <- ""
  if (m[[1]][1] != -1) {
     starts <- attr(m[[1]], "capture.start")
     lengths <- attr(m[[1]], "capture.length")
     for (i in 1:nrow(starts)) {
        alt_text <- substr(txt, starts[i, 1], starts[i, 1] + lengths[i, 1] - 1)
        img_url <- substr(txt, starts[i, 2], starts[i, 2] + lengths[i, 2] - 1)
        link_url <- substr(txt, starts[i, 3], starts[i, 3] + lengths[i, 3] - 1)
        badges_html <- paste0(badges_html, sprintf(
          '<a href="%s" target="_blank" rel="noopener"><img src="%s" alt="%s" style="vertical-align: middle; margin-left: 10px; max-height: 20px;"></a>', 
          link_url, img_url, alt_text
        ))
     }
  }
  
  return(badges_html)
}
print(fetch_github_badges("UofUEpiBio", "epiworld"))
