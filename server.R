library(shiny)
library(dplyr)
library(ggplot2)
library(stringr)

# Include "session" argument for update*() funcitons
shinyServer(function(input, output, session) {
  
  ## New: Dynamic title depending on type of food
  output$dynamicTitle <- renderUI({
    text <- paste0("Investigation of ", str_to_title(input$vore), "vore Mammal Sleep Data")
    h1(text)
  })
  
  ## New: If checkboxInput "REM" is checked, then update sliderInput "size" for min value
  observe({print(input$REM)})
  observeEvent(input$REM, {updateSliderInput(session, "size", min=ifelse(input$REM==TRUE, yes=3, no=1))})
	
  getData <- reactive({
		newData <- msleep %>% filter(vore == input$vore)
	})
	
  #create plot
  output$sleepPlot <- renderPlot({
  	#get filtered data
  	newData <- getData()
  	
  	#create plot
  	g <- ggplot(newData, aes(x = bodywt, y = sleep_total))
  	
  	if(input$conservation){
  	  ## New: If checkboxInput "REM" is checked, then add aes for opacity
  	  if(input$REM){
  	    g + geom_point(size=input$size, aes(col = conservation, alpha = sleep_rem))
  	  }
  	  else{
  	    g + geom_point(size=input$size, aes(col = conservation))
  	  }
  	} else {
  		g + geom_point(size = input$size)
  	}
  })

  #create text info
  output$info <- renderText({
  	#get filtered data
  	newData <- getData()
  	
  	paste("The average body weight for order", input$vore, "is", round(mean(newData$bodywt, na.rm = TRUE), 2),
  	      "and the average total sleep time is", round(mean(newData$sleep_total, na.rm = TRUE), 2), sep = " ")
  })
  
  #create output of observations    
  output$table <- renderTable({
		getData()
  })
  
})
