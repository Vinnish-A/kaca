
.onLoad = function(libname, pkgname) {

  options('kacaUsage' = 'ui')
  if (is.null(getOption('kacaMode'))) {
    options('kacaMode' = 'semi')
  } else if (getOption('kacaMode') %in% c('manu', 'text')) {
    options('kacaMode' = 'semi')
  }

}

#' Make relative path
#'
#' @return relative path
#'
#' @keywords internal
assemble = function(dir_, filename_, ext_, relative_ = T) {

  file_ = normalizePath(file.path(dir_, paste0(filename_, '.', ext_)), mustWork = F)

  if (relative_) {
    file_ = R.utils::getRelativePath(file_, getwd())
  }

  return(file_)

}

#' Make names by rules
#'
#' @return names by rules
#'
#' @keywords internal
makeName = function() {

  if (is.null(getOption('designated'))) options('designated' = getwd())
  if (is.null(getOption('kacaMode'))) options('kacaMode' = 'semi')


  if (getOption('kacaMode') == 'auto') {

    path_ = getOption('designated')
    filename_ = paste(format(Sys.Date(), "%Y%m%d"), basename(tempfile()), sep = '_')

  } else if (getOption('kacaMode') == 'manu') {

    path_ = ''
    filename_ = ''

  } else if (getOption('kacaMode') == 'semi') {

    path_ = getOption('designated')
    filename_ = paste(format(Sys.Date(), "%Y%m%d"), '', sep = '_')

  }

  path_ = R.utils::getRelativePath(normalizePath(getOption('designated')), normalizePath(getwd()))

  return(list(path = path_, filename = filename_))

}

#' findOption
#'
#' @return return options
#'
#' @keywords internal
findOption = function(term_, default_) {

  if (is.null(getOption(term_))) {
    options(term_ = default_)
  }

  res_ = getOption(term_)
  return(res_)

}

#' Check editions
#'
#' @return return null but check options
#'
#' @keywords internal
makeEdit = function(designated_, kacaMode_, insertStyle_, upload_) {

  options('designated' = designated_)
  options('kacaMode' = kacaMode_)
  options('insertStyle' = insertStyle_)
  options('upload' = upload_)

  # if (normalizePath(getwd()) != normalizePath('~') && length(list.files(pattern = 'Rproj')) > 0) {
  #   rprofile_ = '.Rprofile'
  # } else {
  #   rprofile_ = '~/.Rprofile'
  # }
  #
  # if (!file.exists('~/.Rprofile')) file.create('~/.Rprofile')
  # if (!file.exists(rprofile_)) file.create(rprofile_)
  #
  # file_ = suppressWarnings(readLines(rprofile_))
  #
  # # browser()
  # i_ = 1
  # if (!T %in% grepl('created by kaca automatically', file_)) {
  #   if (rprofile_ == '.Rprofile') {
  #     file_ = c(
  #       file_,
  #       'source("~/.Rprofile")',
  #       paste0("options('designated' = '", designated_, "') # created by kaca automatically"),
  #       paste0("options('kacaMode' = '", kacaMode_, "') # created by kaca automatically")
  #     )
  #   } else {
  #     file_ = c(
  #       file_,
  #       paste0("options('designated' = '", designated_, "') # created by kaca automatically"),
  #       paste0("options('kacaMode' = '", kacaMode_, "') # created by kaca automatically")
  #     )
  #   }
  #
  #   i_ = i_ + 1
  # }
  # if (file_[which(grepl('kaca', file_) & grepl('designated', file_))] != paste0("options('designated' = '", designated_, "') # created by kaca automatically")) {
  #   file_[which(grepl('kaca', file_) & grepl('designated', file_))] = paste0("options('designated' = '", designated_, "') # created by kaca automatically")
  #   i_ = i_ + 1
  # }
  # if (file_[which(grepl('kaca', file_) & grepl('kacaMode', file_))] != paste0("options('kacaMode' = '", kacaMode_, "') # created by kaca automatically")) {
  #   file_[which(grepl('kaca', file_) & grepl('kacaMode', file_))] = paste0("options('kacaMode' = '", kacaMode_, "') # created by kaca automatically")
  #   i_ = i_ + 1
  # }
  #
  # if (i_ > 1) {
  #   suppressWarnings(writeLines(file_, rprofile_))
  # }

}

#' Decode encoded base64 then save it as png
#'
#' @return a png picture
#'
#' @importFrom base64enc base64decode
#' @importFrom png readPNG writePNG
#'
#' @keywords internal
decodeAndSave = function(encoded_, to_ = 'mypng.png') {

  raw_ = base64enc::base64decode(what = strsplit(encoded_, split = ',')[[1]][2])
  png::writePNG(png::readPNG(raw_), to_)

}


#' .insertor
#'
#' @param file_
#'
#' @return Return null but insert urls.
.insertor = function (file_, style_ = 'knitr', fig.cap_ = NULL, fig.align_ = NULL) {


  if (fig.cap_ == '')          fig.cap_ = NULL
  if (fig.align_ == 'default') fig.align_ = NULL

  if (style_ == 'knitr') {
    context_ = rstudioapi::getSourceEditorContext()

    head_ = "```{r"
    body_ = sprintf("}\nknitr::include_graphics('%s')\n```\n\n", file_)

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

}

