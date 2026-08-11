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
  
  txt <- paste(ans[1:min(30, length(ans))], collapse = "\n")
  
  pattern <- "\\[\\!\\[([^\\]]*)\\]\\(([^\\)]+)\\)\\]\\(([^\\)]+)\\)"
  matches <- regmatches(txt, gregexec(pattern, txt))[[1]]
  
  badges_html <- ""
  if (length(matches) > 0) {
     for (i in 1:ncol(matches)) {
        alt_text <- matches[2, i]
        img_url <- matches[3, i]
        link_url <- matches[4, i]
        badges_html <- paste0(badges_html, sprintf(
          '<a href="%s" target="_blank" rel="noopener"><img src="%s" alt="%s" style="vertical-align: middle; margin-left: 10px; max-height: 20px;"></a>', 
          link_url, img_url, alt_text
        ))
     }
  }
  
  return(badges_html)
}

print(fetch_github_badges("UofUEpiBio", "epiworld"))
