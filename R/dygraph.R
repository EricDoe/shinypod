#' UI input elements for dygraph module.
#'
#' Used to define the UI input elements within the \code{dygraph} shiny module.
#'
#' This function returns a \code{shiny::\link[shiny]{tagList}} with members:
#'
#' \describe{
#'  \item{time}{\code{shiny::\link[shiny]{selectizeInput}}, used to specify time variable}
#'  \item{y1}{\code{shiny::\link[shiny]{selectizeInput}}, used to specify y1-axis variable}
#'  \item{y2}{\code{shiny::\link[shiny]{selectizeInput}}, used to specify y2-axis variable}
#' }
#'
#' The purpose is to specify the UI elements - another set of functions can be used to specify layout.
#'
#' @family dygraph module functions
#
#' @param id, character used to specify namesapce, see \code{shiny::\link[shiny]{NS}}
#'
#' @return a \code{shiny::\link[shiny]{tagList}} containing UI elements
#'
#' @export
#
dygraph_ui_input <- function(id) {

  ns <- NS(id)

  ui_input <- shiny::tagList()

  ui_input$time <-
    selectizeInput(
      inputId = ns("time"),
      label = "Time",
      choices = NULL,
      selected = NULL,
      multiple = FALSE
    )

  ui_input$y1 <-
    selectizeInput(
      inputId = ns("y1"),
      label = "Y1 axis",
      choices = NULL,
      selected = NULL,
      multiple = TRUE
    )

  ui_input$y2 <-
    selectizeInput(
      inputId = ns("y2"),
      label = "Y2 axis",
      choices = NULL,
      selected = NULL,
      multiple = TRUE
    )

  ui_input
}

#' UI output elements for dygraph module.
#'
#' Used to define the UI output elements within the \code{dygraph} shiny module.
#'
#' Because there are no outputs,
#' this function returns an empty \code{shiny::\link[shiny]{tagList}}.
#'
#' The purpose is to specify the UI elements - another set of functions can be used to specify layout.
#'
#' @family dygraph module functions
#
#' @param id, character used to specify namesapce, see \code{shiny::\link[shiny]{NS}}
#'
#' @return a \code{shiny::\link[shiny]{tagList}}
#'
#' @export
#
dygraph_ui_output <- function(id) {

  ui_output <- shiny::tagList()

  ui_output
}

#' UI miscellaneous elements for dygraph module.
#'
#' Used to define the UI input elements within the \code{dygraph} shiny module.
#'
#' This function returns a \code{shiny::\link[shiny]{tagList}} with members:
#'
#' \describe{
#'  \item{help}{\code{shiny::\link[shiny]{tags}$pre}, contains guidance for using dygraph}
#' }
#'
#' The purpose is to specify the UI elements - another set of functions can be used to specify layout.
#'
#' @family dygraph module functions
#
#' @param id, character used to specify namesapce, see \code{shiny::\link[shiny]{NS}}
#'
#' @return a \code{shiny::\link[shiny]{tagList}} containing UI elements
#'
#' @export
#
dygraph_ui_misc <- function(id) {

  ui_misc <- shiny::tagList()

  ui_misc$help <-
    shiny::tags$pre("Zoom: Click-drag\tPan: Shift-Click-Drag\tReset: Double-Click")

  ui_misc
}


#' Server function for dygraph module.
#'
#' Used to define the server within the \code{dygraph} shiny module.
#'
#' @family read_delim module functions
#
#' @param input   standard \code{shiny} input
#' @param output  standard \code{shiny} output
#' @param session standard \code{shiny} session
#' @param data    data frame or \code{shiny::\link[shiny]{reactive}} that returns a data frame
#'
#' @return a \code{shiny::\link[shiny]{reactive}} that returns a dygraph
#'
#' @examples
#'
#' @export
#
dygraph_server <- function(
  input, output, session,
  data) {

  ns <- session$ns

  ### reactives ###
  #################

  # dataset
  rct_data <- reactive({

    if (shiny::is.reactive(data)) {
      static_data <- data()
    } else {
      static_data <- data
    }

    shiny::validate(
      shiny::need(static_data, "Cannot display graph: no data")
    )

    static_data
  })

  # names of time variables
  rct_var_time <- reactive({

    shinyjs::hide(ns("time"))

    var_time <- df_names_inherits(rct_data(), c("POSIXct"))

    shiny::validate(
      shiny::need(var_time, "Cannot display graph: dataset has no time variables")
    )

    shinyjs::show(ns("time"))

    var_time

  })

  # names of numeric variables
  rct_var_num <- reactive({

    shinyjs::hide(ns("y1"))
    shinyjs::hide(ns("y2"))

    var_num <- df_names_inherits(rct_data(), c("numeric", "integer"))

    shiny::validate(
      shiny::need(var_num, "Cannot display graph: dataset has no numeric variables")
    )

    shinyjs::show(ns("y1"))
    shinyjs::show(ns("y2"))

    var_num
  })

  # names of variables available to y1-axis control
  rct_choice_y1 <- reactive({
    choice_y1 <- setdiff(rct_var_num(), input[["y2"]])

    choice_y1
  })

  # names of variables available to y2-axis control
  rct_choice_y2 <- reactive({
    choice_y2 <- setdiff(rct_var_num(), input[["y1"]])

    choice_y2
  })

  # basic dygraph
  rct_dyg <- reactive({

    var_time <- input[["time"]]
    var_y1 <- input[["y1"]]
    var_y2 <- input[["y2"]]

    shiny::validate(
      shiny::need(
        var_time %in% names(rct_data()),
        "Graph cannot display without a time-variable"
      ),
      shiny::need(
        c(var_y1, var_y2) %in% names(rct_data()),
        "Graph cannot display without any y-variables"
      )
    )

    dyg <- .dygraph(rct_data(), var_time, var_y1, var_y2)

    dyg
  })

  ### observers ###
  #################

  # update choices for time variable
  shiny::observeEvent(
    eventExpr = rct_var_time(),
    handlerExpr = {
      updateSelectInput(
        session,
        inputId = "time",
        choices = rct_var_time(),
        selected = update_selected(input[["time"]], rct_var_time(), index = 1)
      )
    }
  )

  # update choices for y1 variable
  shiny::observeEvent(
    eventExpr = rct_choice_y1(),
    handlerExpr = {
      updateSelectInput(
        session,
        inputId = "y1",
        choices = rct_choice_y1(),
        selected = update_selected(input[["y1"]], rct_choice_y1(), index = 1)
      )
    }
  )

  # update choices for y2 variable
  shiny::observeEvent(
    eventExpr = rct_choice_y2(),
    handlerExpr = {
      updateSelectInput(
        session,
        inputId = "y2",
        choices = rct_choice_y2(),
        selected = update_selected(input[["y2"]], rct_choice_y2(), index = NULL)
      )
    }
  )

  return(rct_dyg)
}


# function that builds basic dygraph
# .dygraph(wx_ames, "date", "temp", "hum")
.dygraph <- function(data, var_time, var_y1, var_y2){

  # create the mts object
  vec_time <- data[[var_time]]
  df_num <- data[c(var_y1, var_y2)]

  # if no tz, use UTC
  tz <- lubridate::tz(vec_time)
  if (identical(tz, "")) {
    tz <- "UTC"
  }

  dy_xts <- xts::xts(df_num, order.by = vec_time, tzone = tz)

  dyg <- dygraphs::dygraph(dy_xts)
  dyg <- dygraphs::dyAxis(dyg, "x", label = var_time)
  dyg <- dygraphs::dyAxis(dyg, "y", label = paste(var_y1, collapse = ", "))
  dyg <- dygraphs::dyAxis(dyg, "y2", label = paste(var_y2, collapse = ", "))

  # put stuff on y2 axis
  for(i in seq_along(var_y2)) {
    dyg <- dygraphs::dySeries(dyg, var_y2[i], axis = "y2")
  }

  dyg
}
