
#' Main UI function
#'
#' @return Inserts selected markdown/knitr link at current location and saves it in designated path.
#'
#' @examples
#' \dontrun{
#'  kaca()
#' }
#'
#' @import shiny
#' @import miniUI
#' @import shinyjs
#' @import htmltools
#' @importFrom shinyWidgets confirmSweetAlert
#'
#' @keywords internal
insert_pic = function() {

  ui_ = function() {

    miniPage(
      shinyjs::useShinyjs(),

      tags$head(
        tags$style(HTML("
          .shiny-output-error-validation {
            color: red;
            font-weight: bold;
          }

          #plotContainer {
            overflow: auto;
            width: 300px;
            height: 340px;
          }
        ")),
        tags$script(
          type = "text/javascript"
          , "focus_searchbox = function() {
            	let select = $('#selected_key').selectize();
            	select[0].selectize.focus();
            };
        ")
      ),

      miniTabstripPanel(
        id = "tabs",

        ## ui_insert ----
        miniTabPanel(
          id = 'insert',
          title = "Save & Insert",
          icon = icon("paste"),
          miniContentPanel(

            tags$body(
              column(
                width = 12,
                column(
                  width = 6,
                  div(id = 'plotContainer', style = "border:1px solid #CCCCCC;", tags$canvas(id = "my_canvas", width = 280, height = 320)),
                  uiOutput('textBar'),
                  uiOutput('whenURL'),
                ),
                column(
                  width = 6, # style = "background-color: #CCCCCC;",
                  div(
                    id = 'infoBox', # style = "background-color: #CCCCCC;",
                    # hr(),
                    HTML('<h5 style = "color: #286090; font-weight: bold;">Host image?</h5>'),
                    column(
                      width = 11, offset = 0.5,
                      radioButtons(
                        inputId = "upload", label = NULL,
                        choices = c('Not', 'Only Upload', 'Save & Upload'), selected = findOption('upload', 'Not'), inline = TRUE
                      )
                    )
                  ),

                  div(
                    id = 'infoBox', # style = "background-color: #CCCCCC;",
                    # hr(),
                    HTML('<h5 style = "color: #286090; font-weight: bold;">Picture infos</h5>'),
                    column(width = 11, offset = 0.5, htmlOutput('widthAndHeight'))
                  ),
                  div(
                    id = 'fileBox',
                    HTML('<h5 style = "color: #286090; font-weight: bold;">Storage settings</h5>'),
                    column(width = 6, align = 'center', textInput('path', label = 'dirname', value = makeName()[[1]])),
                    column(width = 6, align = 'center', textInput('filename', label = 'filename', value = makeName()[[2]])),
                    column(width = 6, align = 'center', textInput('figCap', label = 'fig.cap', placeholder = 'NULL')),
                    column(width = 6, align = 'center', selectizeInput('figAlign', label = 'fig.align', choices = c('default', 'left', 'right', 'center'), selected = 'default'))
                  ),
                  div(
                    id = 'insertBox',
                    HTML('<h5 style = "color: #286090; font-weight: bold;">Style of insertion</h5>'),
                    column(
                      width = 11, offset = 0.5,
                      radioButtons(
                        inputId = "insertStyle", label = NULL,
                        choices = c('markdown(HTML)', 'knitr'), selected = findOption('insertStyle', 'markdown(HTML)'), inline = TRUE
                      )
                    )
                  ),
                  div(
                    id = 'confirmBox', # style = "background-color: #CCCCCC;",
                    # column(width = 6, align = 'center', miniTitleBarButton("saveButton", "Done! ", primary = TRUE)),
                    # column(width = 6, align = 'center', miniTitleBarCancelButton())
                    column(width = 6, align = 'center', tags$button(id="saveButton", type="button", class="btn btn-primary btn-sm action-button", style = 'width: 100px; height: 30px; font-size: 14px', 'Done! ')),
                    column(width = 6, align = 'center', tags$button(id="cancelButton", type="button", class="btn btn-default btn-sm action-button", style = 'width: 100px; height: 30px; font-size: 14px', 'Cancel'))
                  )
                )
              ),
              tags$script(
                HTML(paste(readLines(file.path(system.file(package = 'kaca'), 'srcjs/clipboard.js')), collapse = '\n'))
                # HTML(paste(readLines('inst/srcjs/clipboard.js'), collapse = '\n'))
              )
            )

          )
        ),

        ## ui_host ----
        miniTabPanel(
          id = 'host',
          title = "Image Hosting",
          icon = icon("cog"),
          miniContentPanel(


          )
        )
      )

    )

  }

  server_ = function(input, output, session) {

    output$textBar = renderUI({
      textInput('linkText', label = NULL, placeholder = 'Paste an image or a link', width = '300px')
    })

    output$widthAndHeight = renderUI({
      HTML(
        '<div style="display: flex; justify-content: space-between;">
           <div style="text-align: left;"><strong>Width:  </strong> px</div>
           <div style="text-align: right;"><strong>Height: </strong> px</div>
         </div><p><strong>Extension: </strong></p>'
      )
    })

    observe({
      imageExists_ = length(input$imageInfos) > 0
      filenameWhenSemi_ = input$filename != makeName()[[2]] | getOption('kacaMode') != 'semi'
      if (!is.null(input$urlBehavior) ) {
        filenameWhenRaw_ = input$urlBehavior == 'Insert raw url'
      } else {
        filenameWhenRaw_ = F
      }
      shinyjs::toggleState(
        id ="saveButton",
        condition = imageExists_ & (filenameWhenSemi_ | filenameWhenRaw_)
      )
    })

    observeEvent(
      input$imageInfos,
      if (T) {
        a__ = lapply(input$imageInfos, as.character)
        output$widthAndHeight = renderUI({
          HTML(
            sprintf(
              '<div style="display: flex; justify-content: space-between;">
                 <div style="text-align: left;"><strong>Width:  </strong> %s px</div>
                 <div style="text-align: right;"><strong>Height: </strong> %s px</div>
               </div><p><strong>Extension: </strong> %s </p>',
              a__$width, a__$height, a__$extension
            )
          )
        })
      }
    )

    observeEvent(
      input$placeholder,
      if (input$placeholder == 1) {
        output$textBar = renderUI({
          textInput('linkText', label = NULL, placeholder = 'From Clipboard', width = '300px')
        })

        output$whenURL = renderUI({HTML('')})

      } else if (input$placeholder == 2) {

        output$textBar = renderUI({
          textInput('linkText', label = NULL, placeholder = 'From URL', width = '300px')
        })

        output$whenURL = renderUI({
          column(
            width = 11, offset = 0.5,
            radioButtons(
              inputId = "urlBehavior", label = NULL,
              choices = c('Insert raw url', 'Download to local'), selected = 'Insert raw url', inline = TRUE
            )
          )
        })

      }
    )

    observeEvent(
      input$cancelButton,
      stopApp()
    )

    observeEvent(
      input$saveButton,

        if (input$placeholder == 1) {
          file_ = assemble(input$path, input$filename, input$imageInfos$extension)

          if (input$upload == 'Only Upload') {
            makeEdit(input$path, 'semi', input$insertStyle, input$upload)
            upload2where(filename_ = basename(file_), base64_ = input$base64)
            .insertor(remoteFilepath(filename_ = basename(file_)), input$insertStyle, input$figCap, input$figAlign)
            invisible(stopApp())
          } else if (input$upload == 'Save & Upload') {
            makeEdit(input$path, 'semi', input$insertStyle, input$upload)
            upload2where(filename_ = basename(file_), base64_ = input$base64)
            .insertor(remoteFilepath(filename_ = basename(file_)), input$insertStyle, input$figCap, input$figAlign)
            decodeAndSave(input$base64, file_)
            invisible(stopApp())
          } else {

            if (file.exists(file_)) {

              confirmSweetAlert(
                session = session,
                inputId = "conflict",
                title = "Warning",
                text = paste0(basename(file_), ' already exists!'),
                type = "warning",
                btn_labels = c("Cancel", "Cover it"),
                danger_mode = F
              )

            } else {

              .insertor(file_, input$insertStyle, input$figCap, input$figAlign)
              makeEdit(input$path, 'semi', input$insertStyle, input$upload)
              decodeAndSave(input$base64, file_)
              invisible(stopApp())

            }

          }

        } else {

          file_ = assemble(input$path, input$filename, input$imageInfos$extension)

          if (input$upload == 'Only Upload') {
            makeEdit(input$path, 'semi', input$insertStyle, input$upload)
            upload2where(filename_ = basename(file_), src_ = input$src)
            .insertor(remoteFilepath(filename_ = basename(file_)), input$insertStyle, input$figCap, input$figAlign)
            invisible(stopApp())
          } else if (input$upload == 'Save & Upload') {
            makeEdit(input$path, 'semi', input$insertStyle, input$upload)
            upload2where(filename_ = basename(file_), src_ = input$src)
            .insertor(remoteFilepath(filename_ = basename(file_)), input$insertStyle, input$figCap, input$figAlign)
            tryCatch(download.file(input$src, destfile = file_, mode='wb'), error = \(e) stop('Fail to download...'))
            invisible(stopApp())
          } else {

            if (input$urlBehavior == 'Insert raw url') {

              file_ = input$src

            } else {

              if (file.exists(file_)) {
                confirmSweetAlert(
                  session = session,
                  inputId = "conflict",
                  title = "Warning",
                  text = paste0(basename(file_), ' already exists!'),
                  type = "warning",
                  btn_labels = c("Cancel", "Cover it"),
                  danger_mode = F
                )
              } else {
                tryCatch(download.file(input$src, destfile = file_, mode='wb'), error = \(e) stop('Fail to download...'))
              }

            }

            .insertor(file_, input$insertStyle, input$figCap, input$figAlign)
            makeEdit(input$path, 'semi', input$insertStyle, input$upload)
            invisible(stopApp())


          }

      })

    observeEvent(
      input$conflict,
      if (input$conflict) {

        file_ = assemble(input$path, input$filename, input$imageInfos$extension)
        if (input$placeholder == 1) {
          .insertor(file_, input$insertStyle, input$figCap, input$figAlign)
          makeEdit(input$path, 'semi', input$insertStyle, input$upload)
          decodeAndSave(input$base64, file_)
          invisible(stopApp())
        } else {
          tryCatch(download.file(input$src, destfile = file_, mode='wb'), error = \(e) stop('Fail to download...'))
          .insertor(file_, input$insertStyle, input$figCap, input$figAlign)
          makeEdit(input$path, 'semi', input$insertStyle, input$upload)
          invisible(stopApp())
        }

      }
    )


  }

  viewer_ = dialogViewer("Kaca!", width = 800, height = 500)
  runGadget(ui_, server_, viewer = viewer_)
  # shinyApp(ui_, server_)

}


