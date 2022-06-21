# ui

# Libraries
library(shiny)
library(shinydashboard)

ui <- fluidPage(
  title = "Inflation Rate with FORECASTING",
  titlePanel("Inflation Rate with FORECASTING"),
  br(),
  # img(src='Inf.jpg', align = "right", 
                          # width = '100px', 
                          # height = '100px', alt="Something went wrong", deleteFile = FALSE),
  p("See, how is your money devalved over time, so you need to invest!"),
  
  numericInput(
    inputId = "select_amount",
    label = "Select how much money in CZK: ",
    value = 20000,
    min = 0, max = 1000000, step = 1000
  ),
  
  numericInput(
    inputId = "select_rate",
    label = "Select inflation rate (we start at 3%): ",
    value = 0.03,
    min = 0.01, max = 0.99, step = 0.001
  ),
  
  selectInput(
    inputId = "select_year",
    label = "Select how many years: ",
    choices = c(1:100),
    selected = 5
  ),
  
  p("This is the amount you will have: "),
  verbatimTextOutput("result"), # text
  
  p("This is the amount you will loose: "),
  verbatimTextOutput("difference"), # text
  
  p("This is the percentage you will loose: "),
  verbatimTextOutput("percentage"), # text
  
  plotOutput("years"), # plot
  
  plotOutput("inflation"), # plot
  
  p("See current inflation in Czech Republic: "),
  tableOutput("current"), # text
  
  selectInput(
    inputId = "select_month",
    label = "Select how many months in future: ",
    choices = c(1:100),
    selected = 12
  ),
  
  plotOutput("arima"), # plot
  
  plotOutput("ann"), # plot
  
  p("Source: https://www.czso.cz/csu/czso/mira_inflace"),
)
