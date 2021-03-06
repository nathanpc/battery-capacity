#' app.R
#' Battery capacity Shiny application.
#' 
#' @author Nathan Campos <nathanpc@dreamintech.net>

library("shiny")
source("battery_capacity.R")

#' Gets a list of batteries to populate the CheckboxGroupInput.
#' 
#' @param type Battery type.
battery_list <- function (type) {
  csv = read.csv(paste(datadir, type, "index.csv", sep = "/"))
  names = list()
  files = list()
  
  for (i in 1:nrow(csv)) {
    battery = csv[i,]
    
    if (battery$show == 1) {
      model = battery$model
      capacity = battery$exp_capacity
      
      if (!is.na(model)) {
        if (model != "") {
          model = paste0(" ", model)
        }
      }
      
      if (!is.na(capacity)) {
        capacity = sprintf(" %smAh", capacity)
      } else {
        capacity = ""
      }
      
      names[[sprintf("%s%s %sV%s @ %smA", battery$brand, model, battery$voltage, capacity, battery$current)]] = length(names) + 1
      files[[length(files) + 1]] = paste(datadir, type, battery$file, sep = "/")
    }
  }
  
  return(list(names = names, files = files,
              selected = as.character(1:length(names))))
}

# Shiny UI.
ui <- shinyUI(fluidPage(
  title = "Battery Capacity",
  plotOutput("plot"),
  hr(),
  fluidRow(
    column(3,
           selectInput("batt_type", h4("Battery Type"), as.list(list.dirs(datadir, recursive = FALSE, full.names = FALSE)))
    ),
    column(7,
           checkboxGroupInput("batteries", h4("Batteries"), choices = list("Nothing"))
    )
  )
))

# Shiny server.
server <- shinyServer(function(input, output, session) {
  batt_list = reactive(battery_list(input$batt_type))
  batteries = reactive(get_batteries(input$batt_type))

  observeEvent(input$batteries, {
    show = as.numeric(input$batteries)
    
    output$plot <- renderPlot({
      plot_mah(batteries(), show)
    })
  })
  
  observeEvent(input$batt_type, {
    batt_list = battery_list(input$batt_type)
    batteries = get_batteries(input$batt_type)

    updateCheckboxGroupInput(session, "batteries",
                             choices = batt_list[["names"]],
                             selected = batt_list[["selected"]])
  })
})

shinyApp(ui = ui, server = server)
