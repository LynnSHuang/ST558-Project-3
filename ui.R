library(ggplot2)

shinyUI(fluidPage(
  
  # Application title
  ## New: Change title for what type of vore
  titlePanel(
    uiOutput("dynamicTitle")
    ),
  
  # Sidebar with options for the data set
  sidebarLayout(
    sidebarPanel(
      h3("Select the mammal's biological order:"),
      selectizeInput("vore", "Vore", selected = "omni", choices = levels(as.factor(msleep$vore))),
      br(),
      sliderInput("size", "Size of Points on Graph",
                  min = 1, max = 10, value = 5, step = 1),
      checkboxInput("conservation", h4("Color Code Conservation Status", style = "color:red;")),
      
      ## New: Make new checkbox appear that changes opacity of points based on REM
      conditionalPanel(condition="input.conservation == 1",
                       checkboxInput("REM", "Also change symbol based on REM sleep?"))
    ),
    
    # Show outputs
    mainPanel(
      plotOutput("sleepPlot"),
      textOutput("info"),
      tableOutput("table")
      )
  )
))
