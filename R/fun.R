#' .readIn
#'
#' @return
.readIn = function () {

  is_link_ = F

  img_ = tryCatch(
    expr  = {magick::image_read("clipboard:")},
    error = function (e) {is_link_ <<- T}
  )

  if (is_link_) {
    suppressWarnings({link_ = read.table("clipboard")[1, 1]})

    img_ = tryCatch(
      expr  = {magick::image_read(link_)},
      error = function(e) {stop("This is neither a picture nor a valid link!")}
    )
  }

  return(img_)

}

#' .checkpath
#'
#' @param path_
#'
#' @return
.checkpath = function(path_) {

  tryCatch(
    expr  = {normalizePath(path_, mustWork = T)},
    error = function(e) {stop("Please provide a valid path!")}
  )

}

#' .checkname_
#'
#' @param name_
#'
#' @return
.checkname_ = function(name_) {

  nameFixed_ = trimws(gsub('\"|\'|“|”', '', name_))

  if (!nameFixed_ == name_) cat("Autocorrect the input as", nameFixed_, "\n")

  nameFixed_

}

#' .saveIn
#'
#' @param img_
#' @param name_
#' @param path_
#'
#' @return
.saveIn = function (img_, name_ = NULL, path_ = options("picTmpDir")[[1]]) {

  suffix_ = tolower(unique(magick::image_info(img_)$format))
  if (suffix_ == "webp") suffix_ = "gif"

  if (is.null(name_)) {
    path_ = normalizePath(path_, winslash = "\\", mustWork = F)
    .checkpath(path_)
    file_ = normalizePath(tempfile(tmpdir = path_), winslash = "/", mustWork = F)
  } else if (!getOption("useRelativePath") | is.na(getOption("useRelativePath"))) {
    path_ = normalizePath(path_, winslash = "\\", mustWork = F)
    .checkpath(path_)
    file_ = normalizePath(file.path(path_, name_), winslash = "/", mustWork = F)
  } else {
    .checkpath(path_)
    file_ = file.path(path_, name_)
  }

  if (!is.null(getOption("useRelativePath")) && is.na(getOption("useRelativePath"))) {
    cat("Relative Path is NA, please reset it !")
  }

  file_ = paste0(file_, ".", suffix_)
  magick::image_write(img_, file_, suffix_)

  file_

}

#' .insertor
#'
#' @param file_
#'
#' @return
.insertor = function (file_, style_ = 'knitr', fig.cap_ = NULL, fig.align_ = NULL) {

  if (style_ == 'knitr') {
    context_ = rstudioapi::getSourceEditorContext()

    head_ = "```{r"
    body_ = sprintf('}\nknitr::include_graphics(%s)\n```\n\n', file_)

    if (!is.null(fig.cap_) & !is.null(fig.align_)) {
      head_ = paste0(head_, sprintf(' fig.cap=r"[%s]"', fig.cap_), sprintf(', fig.align="%s"', fig.align_))
      fig.cap_ = NULL
      fig.align_ = NULL
    }

    if (!is.null(fig.cap_)) {
      head_ = paste(head_, sprintf('fig.cap=r"[%s]"', fig.cap_))
    }

    if (!is.null(fig.align_)) {
      head_ = paste(head_, sprintf('fig.align="%s"', fig.align_))
    }

    text_ = paste0(head_, body_)

  } else {
    context_ = rstudioapi::getSourceEditorContext()

    if (is.null(fig.align_) & is.null(fig.align_)) {

      text_ = paste0(sprintf(r"[![](%s)]", file_), '\n\n')

    } else {

      if (is.null(fig.align_)) {
        head_ = '<div class="figure">'
      } else {
        head_ = sprintf('<div class="figure" style="text-align: %s">', fig.align_)
      }

      if (is.null(fig.cap_)) {
        cap_ = NULL
      } else {
        cap_ = sprintf('<p class="caption">%s</p>', fig.cap_)
      }

      body_ = sprintf('<img src="%s"/>', file_)
      tail_ = '</div>\n\n'

      text_ = paste(head_, body_, cap_, tail_, sep = '\n')

    }
  }

  rstudioapi::insertText(text = text_, id = context_$id)

}

#' .autoMode
#'
#' @return
.autoMode = function () {

  img_  = .readIn()
  file_ = .saveIn(img_)

  .insertor(file_)

}

#' .manuMode
#'
#' @return
.manuMode = function () {

  img_  = .readIn()

  cat("Esc to exit\n")
  useRelativePath_ = as.logical(readline("useRelativePath (T/F): "))
  path_ = readline("Set a path: ")
  .checkpath(path_)

  options(useRelativePath = useRelativePath_)
  options(designated = path_)

  name_ = .checkname_(readline("Set a name: "))

  file_ = .saveIn(img_, name_, path_)

  .insertor(file_)


}

#' .semiMode
#'
#' @return
.semiMode = function () {

  img_  = .readIn()

  path_ = getOption("designated")

  if (is.null(path_) | is.na(path_) | nchar(path_) == 0) {
    path_ = readline("Set a path: ")
    .checkpath(path_)
    options(designated = path_)
  }

  useRelativePath_ = getOption("useRelativePath")

  if (is.null(useRelativePath_) | is.na(useRelativePath_)) {
    useRelativePath_ = as.logical(readline("useRelativePath(T/F): "))
    options(useRelativePath = useRelativePath_)
  }

  name_ = .checkname_(readline("Set a name: "))

  file_ = .saveIn(img_, name_, path_)

  .insertor(file_)

}

#' .textMode
#'
#' @return
.textMode = function () {

  file_ = suppressWarnings({link_ = read.table("clipboard")[1, 1]})

  .insertor(file_)

}

#' setPicTmpDir
#'
#' @param path_
#'
#' @return
#' @export
setPicTmpDir = function (path_) {

  .checkpath(path_)
  options(picTmpDir = path_)

  if (!file.exists("~/.Rprofile")) file.create("~/.Rprofile")

  Rprofile = suppressWarnings({readLines("~/.Rprofile")})

  if (length(grep("picTmpDir", Rprofile)) == 0) {
    write(paste0("options(picTmpDir = '", path_, "')"), "~/.Rprofile", append = T, sep = "\n")
  } else {
    Rprofile[grep("picTmpDir", Rprofile)] = paste0("options(picTmpDir = '", path_, "')")
    writeLines(Rprofile, "~/.Rprofile")
  }

}

#' Invoke RStudio add-in to save and insert pictures in clipboard
#'
#' @details The new version of kaca is based on shiny and enables a UI interface.
#' The command-line version will be removed in the next update.
#' The original user operation modes only include {auto} mode and {semi} mode,
#' with {semi} being the default mode.
#'
#' After enabling the Shiny application,
#' press \code{CTRL + V} or any other paste key within the interface,
#' and the application will automatically retrieve images or image links from the clipboard.
#' When there is an image link on the clipboard, you can choose to insert the original link or download the image to local before inserting it.
#'
#' Note that kaca encourages you to give a meaningful name to the image you want to save,
#' so when using modes other than \{auto}, you cannot directly save the image.
#'
#' @return Inserts selected markdown/knitr link at current location and saves it in designated path.
#'
#' @examples
#' \dontrun{
#'  kaca()
#' }
#'
#' @export
kaca = function () {

  if (is.null(getOption('kacaMode'))) {
    options(kacaMode = "auto")
  }

  if (is.null(getOption('kacaUsage'))) {
    options(kacaUsage = "ui")
  }

  if (getOption('kacaUsage') == 'cmd') {

    if (Sys.info()[[1]] != "Windows") warning("Usage 'cmd' only works on Windows.")

    eval(parse(text = paste0("kaca:::.", getOption("kacaMode"), "Mode()")))
    invisible()

  } else if (getOption('kacaUsage') == 'ui') {

    insert_pic()

  }

}

#' kada
#'
#' @export
kada = function () {

  modes_ = c("auto", "manu", "semi", "text")
  mode_  = options("kacaMode")[[1]]
  if (is.null(mode_)) {
    options(kacaMode = "semi")
    mode_ = "semi"
  }

  currently_ = modes_[which(modes_ == mode_) %% 4 + 1]
  following_ = modes_[which(modes_ == currently_) %% 4 + 1]

  options(kacaMode = currently_)

  pointer_ = rep("    ", 4); pointer_[which(modes_ == currently_)] = "--->"

  cat(paste0(c(rep(" ", (getOption("width") - 5) %/% 2), "KaDa!"), collapse = ""), "\n")
  cat(paste0(pointer_, collapse = paste0(rep(" ", (getOption("width") - 16) %/% 3), collapse = "")), "\n")
  cat(paste0(modes_, collapse = paste0(rep("-", (getOption("width") - 16) %/% 3), collapse = "")), "\n")
  cat("\n")
  cat("Currently:", currently_, "\nFollowing:", following_, "\n", sep = "")
  cat("useRelativePath:", getOption("useRelativePath"), "\n")
  cat("Designated Dir:", getOption("designated"), "\n")
  cat("picTmpDir:", getOption("picTmpDir"), "\n")

}

