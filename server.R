# server

server <- function(input, output) {
  options(scipen = 999)
  make_result <- function(x, y, z) {as.numeric(x)*(1+ (-as.numeric(y)/(1+as.numeric(y))) )^as.numeric(z)}
  output$result <- renderText({paste0(round(make_result(input$select_amount, input$select_rate, input$select_year), 2), " CZK")
  })
  
  output$difference <- renderText({ paste0(round(make_result(input$select_amount, input$select_rate, input$select_year), 2) - input$select_amount, " CZK")
  })
  
  output$percentage <- renderText({ paste0(round(((make_result(input$select_amount, input$select_rate, input$select_year)
                                                   /(input$select_amount/100)))-100, 2), " %")
  })
  
  output$years <- renderPlot({
    z_all <- 1:100
    t <- input$select_amount*(1+ (-as.numeric(input$select_rate)/(1+as.numeric(input$select_rate))) )^z_all
    plot(t, type = "l", lwd = 2, col = "red", main = "Inflation over 100 years on your amount", xlab = "Years", ylab = "Amount in CZK")
  })
  
  # CZECH INFLATION
  
  # Libraries
  library(rvest)
  library(dplyr)
  library(forecast)
  library(zoo)
  library(tseries)
  library(curl)
  library(lubridate)
  library(data.table)
  library(plotly)
  library(ggplot2)
  
  load.data <- function(){
    link <- "https://www.czso.cz/csu/czso/mira_inflace"
    inf <- read_html(link)
    
    inf_load <- inf %>% html_nodes("table") %>% .[3] %>% 
      html_table(fill = TRUE) %>% .[[1]]
    
    header.true <- function(df) { # move the first line to the title
      names(df) <- as.character(unlist(df[1,]))
      df[-c(1),]}
    
    inf_load <- data.frame(header.true(inf_load))
    colnames(inf_load) <- c("year", "January", "February", "March",
                            "April", "May", "June", "July", "August",
                            "September", "October", "November", "December")
    
    inf_load$year <- NULL
    
    inf_vector <- as.vector(t(inf_load))
    inf_vector <- as.numeric(gsub(",", ".", inf_vector))
    
    return(inf_vector)
  }
  
  # inf_vector
  inf_vector <- load.data()
  
  transform.data <- function(inf_vector){
    inf_table <- data.table(
      date = seq(as.Date("1997-01-01"), as.Date(paste0(substr(Sys.Date() %m+% months(11), 1, 7), "-01")), by = "month")
    )
    
    len <- length(inf_table$date)
    inf_table$inflation <- inf_vector[1:len]
    inf_table$forecast <- ifelse(is.na(inf_table$inflation), 1, 0)
    
    return(inf_table)
  }
  
  # inf_table
  inf_table <- transform.data(inf_vector)
  
  output$inflation <- renderPlotly ({
    g <- ggplot(inf_table, aes(x=date, y=inflation)) +
      geom_line(col='red', lwd=1) +
      xlab("Date") +
      ylab("Inflation") +
      theme_bw()
  })
  
  output$current <- renderTable ({
    Inflation <- ts(inf_vector, start = c(1997, 1),frequency = 12) # ts
    dmn <- list(month.abb, unique(floor(time(Inflation)))) # df
    current <- as.data.frame(t(matrix(Inflation, 12, dimnames = dmn))) # df
    current <- cbind(Year = rownames(current), current) # index
    rownames(current) <- 1:nrow(current) # index
    current
  })
  
  output$arima <- renderPlot ({
    Inflation <- ts(inf_vector, start = c(1997, 1),frequency = 12) # pred
    Inflation <- na.remove(Inflation)
    arima <- Arima(Inflation, 
                   order = c(2,1,2), 
                   seasonal = c(0,0,1))
    arima <- forecast(arima, h = input$select_month, level=c(0,0))
    plot(arima, lwd = 2, xlab = "Time", ylab = "Inflation")
  })
  
  output$ann <- renderPlot({
    Inflation <- ts(inf_vector, start = c(1997, 1),frequency = 12) # pred
    Inflation <- na.remove(Inflation) 
    fit <- nnetar(Inflation)
    ann <- forecast(fit, h = input$select_month, PI = F) # interval confidence
    plot(ann, lwd = 2, xlab = "Time", ylab = "Inflation")
  })
  
  url <- a("https://www.czso.cz/csu/czso/mira_inflace", href="https://www.czso.cz/csu/czso/mira_inflace")
  output$link <- renderUI({
    tagList("Source:", url)
  })
}
