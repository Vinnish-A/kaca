
.onLoad = function(libname, pkgname) {

  options('kacaUsage' = 'ui')
  if (is.null(getOption('kacaMode'))) {
    options('kacaMode' = 'semi')
  } else if (getOption('kacaMode') %in% c('manu', 'text')) {
    options('kacaMode' = 'semi')
  }

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

#' Check editions
#'
#' @return return null but check options
#'
#' @keywords internal
makeEdit = function(designated_, kacaMode_) {

  options('designated' = designated_)
  options('kacaMode' = kacaMode_)

  if (normalizePath(getwd()) != normalizePath('~') && length(list.files(pattern = 'Rproj')) > 0) {
    rprofile_ = '.Rprofile'
  } else {
    rprofile_ = '~/.Rprofile'
  }

  if (!file.exists(rprofile_)) file.create(rprofile_)

  file_ = readLines(rprofile_)

  # browser()
  i_ = 1
  if (!T %in% grepl('created by kaca automatically', file_)) {
    file_ = c(
      file_,
      paste0("option('designated' = '", designated_, "') # created by kaca automatically"),
      paste0("option('kacaMode' = '", kacaMode_, "') # created by kaca automatically")
    )
    i_ = i_ + 1
  }
  if (file_[which(grepl('kaca', file_) & grepl('designated', file_))] != paste0("option('designated' = '", designated_, "') # created by kaca automatically")) {
    file_[which(grepl('kaca', file_) & grepl('designated', file_))] = paste0("option('designated' = '", designated_, "') # created by kaca automatically")
    i_ = i_ + 1
  }
  if (file_[which(grepl('kaca', file_) & grepl('kacaMode', file_))] != paste0("option('kacaMode' = '", kacaMode_, "') # created by kaca automatically")) {
    file_[which(grepl('kaca', file_) & grepl('kacaMode', file_))] = paste0("option('kacaMode' = '", kacaMode_, "') # created by kaca automatically")
    i_ = i_ + 1
  }

  if (i_ > 1) {
    writeLines(file_, rprofile_)
  }

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
