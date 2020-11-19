library(shiny)
library(shinydashboard)
library(plotly)

dashboardPage(
  skin="red",
  
  # Title
  dashboardHeader(title="1992 NC vs. CA Presidential Election Results", titleWidth=1000),
  
  # Sidebar of different tabs available
  dashboardSidebar(
    sidebarMenu(
      # Describe data, app's purpose, how to use
      menuItem("Information", tabName = "Info", icon = icon("info")),
      # Basic numeric (5 number) and graphical summaries (scatterplot)
      menuItem("Data Exploration", tabName = "DataExp", icon = icon("chart-line")),
      # Unsupervised learning: PCA
      menuItem("Unsupervised Learning", tabName = "Unsup", icon = icon("smile")),
      # Supervised learning: MLR + Boosted Trees
      menuItem("Supervised Learning", tabName = "Sup", icon = icon("smile")),
      # Save subset of data
      menuItem("Save Data", tabName = "SaveData", icon = icon("archive")),
      # Fun
      menuItem("We R Having Fun", tabName="WeRFun", icon = icon("tired"))
    )
  ),
  
  # For each tab, define the body of the app
  dashboardBody(
    tabItems(
      # Info tab
      tabItem(tabName = "Info",
              fluidRow(
                # 1st column on what the app does (total width is 12 for this fluidRow)
                column(width=6,
                       h1("What's this app do?"),
                       box(background="red",
                           width=12,
                           h4("This application examines the 1992 North Carolina vs. California presidential
                              election results with some basic numerical and graphical summaries, unsupervised
                              PCA (principle components analysis), and supervised MLR (multiple linear
                              regression) and boosted trees (an ensemble learning method). You can navigate
                              between the different types of analyses using the tabs on the left."),
                           h4("North Carolina's 14 electoral votes went to the Republican incumbent George
                              H.W. Bush (43.44%), with Bill Clinton (42.65%) and Ross Perot (13.70%) trailing
                              behind. On the other hand, California's 54 electoral votes went neatly to the
                              Democratic challenger Bill Clinton (46.01%), as compared to Bush (32.61%) and
                              Perot (20.63%)."),
                           h4("The Wiki article on the 1992 presidential election has more info here:"),
                           h4(tags$a(href="https://en.wikipedia.org/wiki/1992_United_States_presidential_election", 
                                     "Wikipedia"))
                       )  # End of box
                ),  # End of column
                
                # 2nd column on the data
                column(width=6,
                       h1("What's the data?"),
                       box(background="red",
                           width=12,
                           h4("The data for this app is pulled from the counties.csv file that is provided in 
                              the ST558 class. This data is also available for download from GitHub repository 
                              this app is hosted at. Specifically, only the North Carolina and California state 
                              data is extracted to simplify the app's behind-the-scenes calculations. Also, 
                              because yours truly (the app creator) has been honored to call both North Carolina
                              and California home in recent years.")
                       )  # End of box
                )  # End of column
              )  # End of fluidRow
      ),  # End of Info tab
      
      # DataExp tab will include basic 5-number summaries and scatterplots
      tabItem(tabName = "DataExp",
              fluidRow(
                # 1st skinny column contains user input & dynamic options
                withMathJax(),  # Add in LaTeX functionality for an equation
                column(width=3,
                       h1("Choose Variables"),
                       box(background="red",
                           width=12,
                           selectInput(inputId="var",
                                       label="Numeric Variable to Analyze",
                                       choices=list("pop.density", "pop", "pop.change", "age6574", "age75",
                                                    "crime","college", "income", "farm", "democrat", 
                                                    "republican", "Perot", "white", "black", "turnout"),
                                       selected="pop.density"),
                           
                           # Dynamic: Make description appear depending on selectInput
                           conditionalPanel(condition="input.var == 'pop.density'",
                                            h6("1992 population per square mile")),
                           conditionalPanel(condition="input.var == 'pop'",
                                            h6("1990 population")),
                           conditionalPanel(condition="input.var == 'pop.change'",
                                            h6("Percent change in population from 1980 to 1992")),
                           conditionalPanel(condition="input.var == 'age6574'",
                                            h6("Percent of people between ages 65-74 in 1990")),
                           conditionalPanel(condition="input.var == 'age75'",
                                            h6("Percent of people age 75 and above in 1990")),
                           conditionalPanel(condition="input.var == 'crime'",
                                            h6("Serious crimes per 100,000 people in 1991")),
                           conditionalPanel(condition="input.var == 'college'",
                                            h6("Percent of those age > 25 with bachelor's degree or higher")),
                           conditionalPanel(condition="input.var == 'income'",
                                            h6("Median family income in 1989 dollars")),
                           conditionalPanel(condition="input.var == 'farm'",
                                            h6("Percent living on a farm in 1990")),
                           conditionalPanel(condition="input.var == 'democrat'",
                                            h6("Percent of 1992 presidential election votes for Clinton")),
                           conditionalPanel(condition="input.var == 'republican'",
                                            h6("Percent of 1992 presidential election votes for Bush")),
                           conditionalPanel(condition="input.var == 'Perot'",
                                            h6("Percent of 1992 presidential election votes for Perot")),
                           conditionalPanel(condition="input.var == 'white'",
                                            h6("Percent white in 1990")),
                           conditionalPanel(condition="input.var == 'black'",
                                            h6("Percent black in 1990")),
                           conditionalPanel(condition="input.var == 'turnout'",
                                            p("$$\\frac{1992 Votes Cast}{1990 Population}$$")),
                           
                           # Can choose to subset by NC or CA or all counties
                           radioButtons(inputId="state",
                                        label="Subset counties by state?",
                                        choices=c("All", "CA", "NC"),
                                        selected="All")
                       )  # End of box
                ),  # End of column
                
                # 2nd column (4.5/12) contains numerical summaries
                column(width=4,
                       h1("Numeric Summaries"),
                       box(width=12,
                           tableOutput("NumSumTab")
                       )
                ),
                # 3rd column (4.5/12) contains graphical summary
                column(width=5,
                       h1("Histogram"),
                       box(width=12,
                           downloadButton("downGraphSumPlot", 'Download Plot'),
                           h4("Mouse over the plot to view the bin ranges and number of items per bin."),
                           plotlyOutput("GraphSumPlot")
                           #plotOutput("GraphSumPlot")    # Old ggplot version
                       )
                )  # End of column
              )  # End of row
      ),  # End of tab
      
      # Unsup tab will include unsupervised learning (PCA) applied to the data
      # Dynamic: User can choose how many PCs to report
      tabItem(tabName = "Unsup",
              h1("Principal Components Analysis"),
              fluidRow(
                # 1st skinny column to describe PCA and give options for which PCs to show in biplot
                # There are 15 numeric variables, so you can have up to 15 PCs
                column(width=3,
                       box(background="red",
                           width=12,
                           h4("Which variables should we include in the PCA? Note that checking more will make
                              for a messier looking biplot."),
                           checkboxGroupInput(inputId="varPCs",
                                              label="Variables for Principal Components Analysis",
                                              choices=list("pop.density", "pop", "pop.change", "age6574", "age75",
                                                           "crime", "college", "income", "farm", "democrat",
                                                           "republican", "Perot", "white", "black", "turnout"),
                                              selected=c("college", "income", "democrat")),
                           h4("Please make sure you only tick 2 PCs! This app will automatically display PC1 and
                              PC2 in the biplot."),
                           checkboxGroupInput(inputId="numPCs",
                                              label="Numbers of Principal Components to Display in Biplot",
                                              choices=list("1", "2", "3", "4", "5", "6", "7", "8", "9", "10"),
                                              selected=c("1", "2")),
                           # Only update plots when actionButton called (avoid intermediate error states)
                           actionButton(inputId="GoBiPlot",
                                        label="Update BiPlot")
                       )  # End of box
                ),  # End of column
                
                # 2nd fatter column to show biplot
                column(width=9,
                       box(background="red",
                           width=12,
                           downloadButton("downBiPlot", 'Download Plot'),
                           plotOutput("biPlot")
                       )
                )  # End of column
              )  # End of row
      ),  # End of tab
      
      # Sup tab will include supervised models (MLR + Boosted Trees)
      # Dynamic: User can choose which vars to include, how many trees for boosting
      tabItem(tabName = "Sup",
              fluidRow(
                # 1st skinny column to choose variables in MLR or Boosted Trees
                column(width=2,
                       box(background="red",
                           width=12,
                           h4("Let's train models to predict the democrat vote percentage. Ross Perot only won
                               2/158 counties, so we'll drop him from the analysis. We'll make a linear regression 
                               model and a boosted trees model."),
                           h4("What variables should we include in the supervised model?"),
                           checkboxGroupInput(inputId="varSup",
                                              label="Variables for Supervised Model",
                                              choices=list("state", "pop.density", "pop", "pop.change",
                                                           "age6574", "age75", "crime", "college", "income",
                                                           "farm", "white", "black", "turnout"),
                                              selected=c("state","pop","age6574","college","income","white")),
                           numericInput(inputId="cvPerc",
                                        label="Percentage for CV Training Data",
                                        value = 0.80, min = 0.01, max = 0.99),
                           numericInput(inputId="nTrees",
                                        label="Minimum Number of Trees",
                                        value=1000, min=1, max=2000),
                           # Only update models and plots when actionButton called
                           actionButton(inputId="GoMLR",
                                        label="Do Linear Regression"),
                           actionButton(inputId="GoBoost",
                                        label="Do Boosted Trees"),
                           h6("Please note boosted model is slow!")
                       )  # End of box
                ),  # End of column
                column (width=10,
                        # Put a top row of MLR and Boost results
                        fluidRow(
                          # 2nd fatter column for MLR
                          column(width=5,
                                 box(background="red",
                                     width=12,
                                     h3("Multiple Linear Regression Results"),
                                     h5("Model Fit from 5-fold Cross-Validation"),
                                     verbatimTextOutput("summMLR"),
                                     h5("Calculated RMSE on Test Data"),
                                     verbatimTextOutput("errMLR")
                                 )  # End of box
                          ),  # End of column
                          # 3rd fatter column for Boosted Trees
                          column(width=5,
                                 box(background="red",
                                     width=12,
                                     h3("Boosted Tree Results"),
                                     h5("Best Tune from 5-fold CV"),
                                     verbatimTextOutput("summBoost"),
                                     h5("Calculated RMSE on Test Data"),
                                     verbatimTextOutput("errBoost")
                                 )  # End of box
                          )  # End of column
                        ),  # End of fluidRow of MLR and Boost results
                        
                        # Put a bottom fluidRow of predictions
                        fluidRow(
                          column(width=10,
                                 box(background="red",
                                     width=12,
                                     radioButtons(inputId="predModel",
                                                  label="Model to Use for Prediction",
                                                  choices=list("Linear Regression", "Boosted Trees"),
                                                  selected="Linear Regression",
                                                  inline=TRUE),
                                     h5("Currently, mean values are used for prediction. Feel free to adjust."),
                                     h5("Linear Regression Prediction: "),
                                     verbatimTextOutput("predMLR"),
                                     h5("Boosted Trees Prediction: "),
                                     #verbatimTextOutput("predBoost"),
                                     selectInput(inputId="stateVal", label="state",
                                                 choices=list("CA","NC"), selected="CA"),
                                     numericInput(inputId="pop.densityVal", label="pop.density",
                                                  value=305, min=2, max=15609, step=1),
                                     numericInput(inputId="popVal", label="pop",
                                                  value=232662, min=1113, max=8863164, step=1),
                                     numericInput(inputId="pop.changeVal", label="pop.change",
                                                  value=20.0, min=-8.7, max=94.3, step=0.1),
                                     numericInput(inputId="age6574Val", label="age6574",
                                                  value=8.1, min=2.9, max=13.9, step=0.1),
                                     numericInput(inputId="age75Val", label="age75",
                                                  value=5.4, min=1.5, max=10.9, step=0.1),
                                     numericInput(inputId="crimeVal", label="crime",
                                                  value=4432, min=0, max=11154, step=1),
                                     numericInput(inputId="collegeVal", label="college",
                                                  value=14.9, min=6.6, max=46.1, step=0.1),
                                     numericInput(inputId="incomeVal", label="income",
                                                  value=30908, min=18377, max=59157, step=1),
                                     numericInput(inputId="farmVal", label="farm",
                                                  value=2.6, min=0, max=13.4, step=0.1),
                                     numericInput(inputId="whiteVal", label="white",
                                                  value=77.17, min=36.12, max=99.45, step=0.01),
                                     numericInput(inputId="blackVal", label="black",
                                                  value=15.61, min=0.01, max=61.46, step=0.01),
                                     numericInput(inputId="turnoutVal", label="turnout",
                                                  value=40.84, min=16.23, max=59.72, step=0.01)
                                 ) # End of box
                          )  # End of column
                        )  # End of fluidRow of predictions
                ) # End of column on right with all results
              )  # End of fluidRow
      ),  # End tab
      
      # SaveData tab will include scrollable data that user can subset and save to CSV
      tabItem(tabName = "SaveData",
              # SaveData: Subset data for saving
              fluidRow(
                box(background = "red",
                    width=12,
                    checkboxGroupInput(inputId="varSubset",
                                       label="Variables to Download",
                                       choices=list("region", "county", "state", "msa", "pmsa", "pop.density", 
                                                    "pop", "pop.change", "age6574", "age75", "crime", "college",
                                                    "income", "farm", "democrat", "republican", "Perot", "white",
                                                    "black", "turnout"),
                                       selected=c("county", "democrat", "republican", "Perot")),
                    downloadButton("downCSV", 'Download Data')
                )  # End of box
              ),  # End of fluidRow
              fluidRow(dataTableOutput("dataTbl"))
      ), # End tab
      
      # Funny Image tab to end with
      tabItem(tabName = "WeRFun",
              h4(tags$b("Thanks so much for coming to check out my app! Questions or comments? 
                         Please check my blog out for more fun (and contact info).
                         Complaints will be addressed not so promptly.")),
              h4(tags$a(href="https://lynnshuang.github.io/about/", "Say Hi!")),
              h4(tags$a(href="https://images.app.goo.gl/8QH84SSgv5kVDhSd8", "Coding Memes"))
      ) # End tab
    )  # End tabItems
  )  # End dashboardBody
)  # End of dashboardPage