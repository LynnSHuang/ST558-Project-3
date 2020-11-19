library(shiny)
library(tidyverse)
library(dplyr)
library(ggplot2)
library(plotly)
library(knitr)
library(caret)

# Include "session" argument for dynamic update*() functions
shinyServer(function(input, output, session) {
  ## Load data from CSV file first
  elections.raw <- read_csv(file = "./1992Election.csv", col_names = TRUE)
  # Remove the msa, pmsa NA-containing cols
  elections <- elections.raw %>% select(-msa, -pmsa)
  # Add classification column of D/R/P winner by largest percentage
  elections$winner <- "D"
  elections$winner[elections$republican > elections$democrat] <- "R"
  elections$winner[elections$Perot > elections$republican] <- "P"
  elections <- elections %>% filter(winner != "P")
  elections.DRP <- elections
  elections$winner <- ifelse(elections$winner=="D", 1, 0)
  # Make factors
  elections$region <- as.factor(elections$region)
  elections$county <- as.factor(elections$county)
  elections$state <- as.factor(elections$state)
  elections$winner <- as.factor(elections$winner)
  
  ## Create reactive place to store ggplots
  vals <- reactiveValues(g=NULL)
  
  ## DataExp: Create dataframe of numeric summaries and render it
  getNumSum <- reactive({
    # If input$state == "All", then don't filter data at all
    if (input$state == "All") {
      df <- elections %>% select(input$var)
    }
    else {
      df <- elections %>% filter(state == input$state) %>% select(input$var)
    }
		df <- unlist(df)
		df.numSum <- as.data.frame(c(quantile(df, probs=c(0, 0.25, 0.5, 0.75, 1)), mean(df), sd(df)),
		                           row.names= c("Minimum", "1st Quartile", "Median", "3rd Quartile",
		                                        "Maximum", "Mean", "Standard Deviation"),
		                           col.names="")
	})
  output$NumSumTab <- renderTable({getNumSum()},
                                  include.rownames=TRUE,
                                  include.colnames=FALSE,
                                  align="r")
  # DataExp: Get data for var of interest
  getData <- reactive(
    # If input$state == "All", then don't filter data at all
    if (input$state == "All") {
      df <- elections %>% select(input$var)
    }
    else {
      df <- elections %>% filter(state == input$state) %>% select(input$var)
    }
  )
  # DataExp: Create histogram and render it with plotly (interactive)
  output$GraphSumPlot <- renderPlotly({
    # Filter data
    df <- getData()
    # Create scatterplot that is interactive
    g <- plot_ly(x=df[[input$var]], type="histogram")
    vals$g <- g
    g
  })
  # DataExp: Create histogram and render it with ggplot2
  # output$GraphSumPlot <- renderPlot({
  #   df <- getData()
  #   g <- ggplot(df, aes_string(x = input$var)) +
  #     geom_histogram(bins=20) +
  #     labs(title=paste0("Histogram of ", input$var), xlab=toString(input$var), ylab="Count")
  #   vals$g <- g
  #   g
  # })
  # DataExp: Can download histogram to PNG
  output$downGraphSumPlot <- downloadHandler(filename=function(){paste0("Graphic Summary ",input$var,".png")},
                                             content=function(file){
                                               png(file)
                                               print(vals$g)
                                               dev.off()
                                               }
                                             )
  
  ## Unsup: Get filtered data for PC
  getPCData <- reactive(
    df.PCs <- elections %>% select(input$varPCs)
  )
  # Unsup: Dynamic: Observe how many varPCs chosen and update the numPCs allowed
  choices.PCs <- list("1", "2", "3", "4", "5", "6", "7", "8", "9", "10")
  observe({updateCheckboxGroupInput(session,
                                    "numPCs",
                                    choices=choices.PCs[1:length(input$varPCs)],
                                    selected=c("1", "2"))})
  # Unsup: IF action button pressed, Do PCA and render biplot
  # !isolate() will remove the dependency of renderPlot on input$numPCs changing from user input. No errors!
  observeEvent(input$GoBiPlot,
               {output$biPlot <- renderPlot({
                 df.PCs <- getPCData()
                 PCs <- prcomp(df.PCs, center=TRUE, scale=TRUE)
                 biplot(PCs, xlabs=elections$winner, choices=isolate(as.numeric(input$numPCs)))
                 })
               })
  # Unsup: Can download biplot to PNG
  output$downBiPlot <- downloadHandler(filename="Biplot of PCs.png",
                                       content=function(file){
                                               png(file)
                                               print(biplot(PCs,
                                                            xlabs=elections$winner,
                                                            choices=as.numeric(input$numPCs)))
                                               dev.off()
                                       }
                                       )
  
  ## Sup: Get filtered data for MLR
  SupData <- reactiveValues(df=NULL, train=NULL, test=NULL, preProc=NULL, o.mlr=NULL)
  # Sup: IF action button pressed, do MLR
  observeEvent(input$GoMLR,
               {# Make training and test data sets
                 SupData$df <- elections %>% select(input$varSup, democrat)
                 trainIndex <- sample(1:nrow(SupData$df), size = nrow(SupData$df)*input$cvPerc)
                 trainData <- SupData$df[trainIndex, ]
                 testData <- SupData$df[-trainIndex, ]
                 # Pre-process data
                 SupData$preProc <- preProcess(trainData, method=c("center", "scale"))
                 SupData$train <- predict(SupData$preProc, trainData)
                 SupData$test <- predict(SupData$preProc, testData)
                 
                 # Sup: Print out results of linear regression
                 output$summMLR <- renderPrint({
                   SupData$o.mlr <- train(democrat ~ ., 
                                          data=SupData$train, 
                                          method="lm", 
                                          trControl=trainControl(method="cv", number=5))
                   summary(SupData$o.mlr)
                 })
                 # Sup: Print out results of predicting on test set
                 output$errMLR <- renderPrint({
                   rmse.mlr <- sqrt(mean((SupData$test$democrat - predict(SupData$o.mlr, newdata=SupData$test))^2))
                   rmse.mlr
                 })
                 # Sup: Print out results of new prediction
                 output$predMLR <- renderPrint({
                   df.new <- data.frame(state=input$stateVal, pop.density=input$pop.densityVal, pop=input$popVal,
                                        pop.change=input$pop.changeVal, age6574=input$age6574Val, 
                                        age75=input$age75Val, crime=input$crimeVal, college=input$collegeVal,
                                        income=input$incomeVal, farm=input$farmVal, white=input$whiteVal,
                                        black=input$blackVal, turnout=input$turnoutVal, democrat=0.0)
                   # Get only relevant vars and preprocess so it matches center/scale
                   df.new <- predict(SupData$preProc, df.new)
                   df.new$democrat <- NULL
                   predict(SupData$o.mlr, newdata=df.new)
                 })
               })
  # Sup: Get filtered data for Boosted Trees
  SupDataBoost <- reactiveValues(df=NULL, train=NULL, test=NULL, preProc=NULL, o.boost=NULL)
  # Sup: IF action button pressed, do Boosted Trees
  observeEvent(input$GoBoost,
              {# Make training and test data sets (same as in MLR)
                SupDataBoost$df <- elections %>% select(input$varSup, democrat)
                trainIndex <- sample(1:nrow(SupDataBoost$df), size = nrow(SupDataBoost$df)*input$cvPerc)
                trainData <-  SupDataBoost$df[trainIndex, ]
                testData <- SupDataBoost$df[-trainIndex, ]
                # Pre-process data
                SupDataBoost$preProc <- preProcess(trainData, method=c("center", "scale"))
                SupDataBoost$train <- predict(SupDataBoost$preProc, trainData)
                SupDataBoost$test <- predict(SupDataBoost$preProc, testData)
                # Sup: Print out results of boosted trees classifier
                output$summBoost <- renderPrint({
                  SupDataBoost$o.boost <- train(democrat ~ .,
                                                data=SupDataBoost$train,
                                                method="gbm",
                                                distribution="gaussian",
                                                trControl=trainControl(method="cv", number=5),
                                                tuneGrid=data.frame(
                                                  expand.grid(n.trees=c(input$nTrees*1, input$nTrees*2),
                                                              interaction.depth=c(1, 5),
                                                              shrinkage=c(0.001, 0.01, 0.1),
                                                              n.minobsinnode=c(1, 2, 3)
                                                  )
                                                ),
                                                verbose=FALSE
                  )
                   SupDataBoost$o.boost$bestTune
                   }) # End of summBost
                # Sup: Print out results of predicting on test set
                #output$errBoost <- renderPrint({"Ho!"})
                 output$errBoost <- renderPrint({
                   rmse.boost <- sqrt(mean((SupDataBoost$test$democrat - 
                                              predict(SupDataBoost$o.boost, newdata=SupDataBoost$test))^2))
                   rmse.boost
                 })
                 # Sup: Print out results of new prediction
                 output$predBoost <- renderPrint({
                   df.new <- data.frame(state=input$stateVal, pop.density=input$pop.densityVal, pop=input$popVal,
                                        pop.change=input$pop.changeVal, age6574=input$age6574Val, 
                                        age75=input$age75Val, crime=input$crimeVal, college=input$collegeVal,
                                        income=input$incomeVal, farm=input$farmVal, white=input$whiteVal,
                                        black=input$blackVal, turnout=input$turnoutVal, democrat=0.0)
                   # Get only relevant vars and preprocess so it matches center/scale
                   df.new <- predict(SupDataBoost$preProc, df.new)
                   df.new$democrat <- NULL
                   predict(SupDataBoost$o.Boost, newdata=df.new)
                 })
                }) # End of observeEvent

  ## SaveData: If new vars checked/unchecked, include them in the viewed subsetted data
  getSubData <- reactive({
    df <- elections.raw %>% select(input$varSubset)
  })
  output$dataTbl <- renderDataTable(getSubData())
  output$downCSV <- downloadHandler(filename=function() {paste0("elections.csv")},
                                    content=function(file) {write.csv(getSubData(), file, row.names = FALSE)}
  )
  }) # End of shinyServer
