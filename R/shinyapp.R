
#' Main UI function
#'
#' @return Inserts selected markdown/knitr link at current location and saves it in designated path.
#'
#' @examples
#' \dontrun{
#'  kaca()
#' }
#'
#' @import miniUI
#' @import shiny
#' @import shinyjs
#' @import htmltools
#' @importFrom shinyWidgets confirmSweetAlert
#'
#' @keywords internal
insert_pic = function() {

  ui_ = miniPage(
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
            height: 300px;
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
      miniTabPanel(
        title = "Save & Insert",
        icon = icon("paste"),
        miniContentPanel(

          tags$body(
            column(
              width = 12,
              column(
                width = 6,
                div(id = 'plotContainer', style = "border:1px solid #CCCCCC;", tags$canvas(id = "my_canvas", width = 280, height = 280)),
                uiOutput('textBar'),
                uiOutput('whenURL'),
              ),
              column(
                width = 6, # style = "background-color: #CCCCCC;",
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
                  column(width = 6, align = 'center', selectizeInput('figAlign', label = 'fig.align', choices = c('default', 'left', 'right', 'center'), selected = 'center'))
                ),
                div(
                  id = 'insertBox',
                  HTML('<h5 style = "color: #286090; font-weight: bold;">Style of insertion</h5>'),
                  column(
                    width = 11, offset = 0.5,
                    radioButtons(
                      inputId = "insertStyle", label = NULL,
                      choices = c('markdown(HTML)', 'knitr'), selected = 'markdown(HTML)', inline = TRUE
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
              HTML(paste(readLines('R/clipboard.js'), collapse = '\n'))
            )
          )

        )
      ),

      miniTabPanel(
        title = "Image Hosting",
        icon = icon("cog")
      )
    )

  )

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
      shinyjs::toggleState(id ="saveButton", condition = !is.null(input$imageInfos) & input$filename != makeName()[[2]] & getOption('kacaMode') == 'semi')
    })

    observeEvent(
      input$imageInfos,
      if (T) {
        a__ = lapply(input$imageInfos, as.character)
        # browser()
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
        file_ = normalizePath(file.path(input$path, paste0(input$filename, input$extension)), mustWork = F)

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
          makeEdit(input$path, 'semi')
          decodeAndSave(input$base64, file_)
          invisible(stopApp())

        }

      } else {

        if (input$urlBehavior == 'Insert raw url') {

          file_ = input$src

        } else {

          file_ = normalizePath(file.path(input$path, paste0(input$filename, input$extension)), mustWork = F)
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
        makeEdit(input$path, 'semi')
        invisible(stopApp())

      }
    )

    observeEvent(
      input$conflict,
      if (input$conflict) {

        if (input$placeholder == 1) {
          .insertor(file_, input$insertStyle, input$figCap, input$figAlign)
          makeEdit(input$path, 'semi')
          decodeAndSave(input$base64, file_)
          invisible(stopApp())
        } else {
          tryCatch(download.file(input$src, destfile = file_, mode='wb'), error = \(e) stop('Fail to download...'))
          .insertor(file_, input$insertStyle, input$figCap, input$figAlign)
          makeEdit(input$path, 'semi')
          invisible(stopApp())
        }

      }
    )

  }

  viewer_ = dialogViewer("Kaca!", width = 800, height = 450)
  runGadget(ui_, server_, viewer = viewer_)
  # shinyApp(ui_, server_)

}


