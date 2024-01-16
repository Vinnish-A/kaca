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
    file_ = normalizePath(tempfile(tmpdir = path_), winslash = "/", mustWork = F)
  } else if (!getOption("useRelativePath") | is.na(getOption("useRelativePath"))) {
    path_ = normalizePath(path_, winslash = "\\", mustWork = F)
    file_ = normalizePath(file.path(path_, name_), winslash = "/", mustWork = F)
  } else {
    file_ = file.path(path_, name_)
  }

  if (is.na(getOption("useRelativePath"))) cat("Relative Path is NA, please reset it !")

  file_ = paste0(file_, ".", suffix_)
  magick::image_write(img_, file_, suffix_)

  file_

}

#' .insertor
#'
#' @param file_
#'
#' @return
.insertor = function (file_) {

  context_ = rstudioapi::getSourceEditorContext()
  text_ = paste0("```{r}\nknitr::include_graphics('", file_, "')\n```")

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
  useRelativePath_ = as.logical(readline("useRelativePath(T/F): "))
  path_ = readline("Set a path: ")

  options(designated = path_)
  options(useRelativePath = useRelativePath_)

  name_ = readline("Set a name: ")

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
    options(designated = path_)
  }

  useRelativePath_ = getOption("useRelativePath")

  if (is.null(useRelativePath_) | is.na(useRelativePath_)) {
    useRelativePath_ = as.logical(readline("useRelativePath(T/F): "))
    options(useRelativePath = useRelativePath_)
  }

  name_ = readline("Set a name: ")

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

#' kaca
#'
#' @param mode_
#'
#' @return
#' @export
kaca = function (mode_ = options("kacaMode")[[1]]) {

  if (is.null(mode_)) {
    options(kacaMode = "auto")
    mode_ = "auto"
  }

  eval(parse(text = paste0("kaca:::.", mode_, "Mode()")))
  invisible()

}

#' kada
#'
#' @param mode_
#'
#' @return
#' @export
kada = function () {

  modes_ = c("auto", "manu", "semi", "text")
  mode_  = options("kacaMode")[[1]]
  if (is.null(mode_)) {
    options(kacaMode = "auto")
    mode_ = "auto"
  }

  current_ = modes_[which(modes_ == mode_) %% 4 + 1]
  follow_ = modes_[which(modes_ == current_) %% 4 + 1]

  options(kacaMode = current_)

  pointer_ = rep("    ", 4); pointer_[which(modes_ == current_)] = "--->"

  cat(paste0(c(rep(" ", (getOption("width") - 5) %/% 2), "KaDa!"), collapse = ""), "\n")
  cat(paste0(pointer_, collapse = paste0(rep(" ", (getOption("width") - 16) %/% 3), collapse = "")), "\n")
  cat(paste0(modes_, collapse = paste0(rep("-", (getOption("width") - 16) %/% 3), collapse = "")), "\n")
  cat("\n")
  cat("Currently:", current_, "\nFollowing:", follow_, "\n", sep = "")
  cat("useRelativePath:", getOption("useRelativePath"), "\n")
  cat("Designated Dir:", getOption("designated"), "\n")
  cat("picTmpDir:", getOption("picTmpDir"), "\n")

}

