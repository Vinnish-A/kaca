
#' upload2where
#'
#' @return Inserts selected markdown/knitr link at current location and saves it in designated path.
#'
#' @import httr
#' @import jsonlite
#' @import base64enc
#'
#' @keywords internal
upload2where = function(where_ = tolower(Sys.getenv('HOST_SERVICE')), filename_, base64_ = NULL, src_ = NULL) {

  if (!is.null(src_)) {
    response_ = tryCatch(GET(src_), error = \(e) stop('Fail to download...'))
    content_ = content(response_, "raw")
    base64_ = base64encode(content_)
    src_ = T
  } else {
    src_ = F
  }

  do.call(paste0('upload2', where_), list(filename_ = filename_, content_ = base64_, src_ = src_))

}

#' remoteFilepath
#'
#' @return path to file in repos
#'
#' @keywords internal
remoteFilepath = function(where_ = tolower(Sys.getenv('HOST_SERVICE')), filename_) {

  repos_ = Sys.getenv(paste0(toupper(Sys.getenv('HOST_SERVICE')), '_REPOS'))

  res_ = switch(
    where_,
    github = file.path('https://github.com', repos_, 'blob', Sys.getenv("GITHUB_BRANCH"), filename_),
    gitee = file.path('https://gitee.com', repos_, 'blob', Sys.getenv("GITEE_BRANCH"), filename_)
  )

  if (length(Sys.getenv('GITHUB_ACTION')) > 0) {
    res_ = file.path(Sys.getenv('GITHUB_ACTION'), filename_)
  }

  return(res_)

}

#' upload2gitee
#'
#' @return Return null but upload file to repos(gitee)
#'
#' @keywords internal
upload2gitee = function(filename_, content_, src_) {

  token_ = Sys.getenv("GITEE_TOKEN")
  repo_ = Sys.getenv("GITEE_REPOS")
  branch_ = Sys.getenv("GITEE_BRANCH")

  url_ = sprintf("https://gitee.com/api/v5/repos/%s/contents/%s", repo_, filename_)

  body_ = list(
    access_token = token_,
    message = "Upload image",
    content = content_,
    branch = branch_
  )

  response_ = POST(
    url_,
    body = body_,
    encode = "form"
  )

  if (status_code(response_) == 201) {
    words_ = sprintf('Upload %s to %s successfully! ', filename_, url_)
    message(words_)
  } else {
    invisible(stopApp())
    words_ = sprintf("Failed to upload %s\nstatus:\n%s", filename_, content(response_, "text", encoding = "UTF-8"))
    warning(words_)
  }

}

#' upload2github
#'
#' @return Return null but upload file to repos(github)
#'
#' @keywords internal
upload2github = function(filename_, content_, src_ = F) {

  token_ = Sys.getenv("GITHUB_TOKEN")
  repo_ = Sys.getenv("GITHUB_REPOS")
  branch_ = Sys.getenv("GITHUB_BRANCH")

  url_ = sprintf("https://api.github.com/repos/%s/contents/%s", repo_, filename_)

  body_ = list(
    message = "Upload image",
    content = ifelse(src_, content_, substr(content_, 23, nchar(content_))),
    # content = xxx,
    branch = branch_
  )

  response_ = PUT(
    url_,
    add_headers(Authorization = paste("token", token_)),
    body = toJSON(body_, auto_unbox = TRUE),
    encode = "json"
  )

  if (status_code(response_) == 201) {
    words_ = sprintf('Upload %s to %s successfully! ', filename_, url_)
    message(words_)
  } else {
    invisible(stopApp())
    words_ = sprintf("Failed to upload %s\nstatus:\n%s", filename_, content(response_, "text", encoding = "UTF-8"))
    warning(words_)
  }

}

#' .editor
#'
#' @keywords internal
.editor = function(text_) {

  rstudioapi::documentOpen('~/.Renviron')
  context_ = rstudioapi::getSourceEditorContext()
  rstudioapi::insertText(text = text_, id = context_$id)

}

#' .sentenceMaker
#'
#' @keywords internal
.sentenceMaker = function(terms_) {

  notes_ = '# Github Environ | Remember to delete these comments | Created by kaca automatically'
  terms_ = terms_[sapply(terms_, \(term__) length(Sys.getenv(term__)) == 1)]

  if (length(terms_) > 0) {
    sentences_ = paste(paste0(terms_, "=''", notes_), collapse = '\n')
  } else {
    sentences_ = NULL
  }

  return(sentences_)

}

#' Add necessary configurations in ~/.Renviron for gitee.
#'
#' @return Return null but open `~/.Renviron` then insert configurations.
#'
#' @export
edit_environ_gitee = function() {

  terms_ = c('host_service', paste0('gitee_', c('token', 'repos', 'branch'))) |> toupper()
  sentences_ = .sentenceMaker(terms_)
  .editor(sentences_)

}

#' Add necessary configurations in ~/.Renviron for github.
#'
#' @return Return null but open `~/.Renviron` then insert configurations.
#'
#' @export
edit_environ_github = function() {

  terms_ = c('host_service', paste0('github_', c('token', 'repos', 'branch'))) |> toupper()
  sentences_ = .sentenceMaker(terms_)
  .editor(sentences_)

}

#' Add necessary configurations in ~/.Renviron for github action service.
#'
#' @return Return null but open `~/.Renviron` then insert configurations.
#'
#' @export
edit_environ_githubAction = function() {

  terms_ = paste0('github_', c('token', 'repos', 'branch', 'action')) |> toupper()
  sentences_ = .sentenceMaker(terms_)
  .editor(sentences_)

}
