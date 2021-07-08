# server
server <- function(input, output) {
  
  make_result <- function(x, y, z) {as.numeric(x)*(1-as.numeric(y))^as.numeric(z)}
  output$result <- renderText({paste0(round(make_result(input$select_amount, input$select_rate, input$select_year), 2), " CZK")
  })
  
  output$difference <- renderText({ paste0(round(make_result(input$select_amount, input$select_rate, input$select_year), 2) - input$select_amount, " CZK")
  })
  
  output$percentage <- renderText({ paste0(round(((make_result(input$select_amount, input$select_rate, input$select_year)
                                                   /(input$select_amount/100)))-100, 2), " %")
  })
  
  output$years <- renderPlot({
    z_all <- 1:100
    t <- input$select_amount*(1-input$select_rate)^z_all
    plot(t, type = "l", lwd = 2, col = "red", main = "Inflation over 100 years on your amount", xlab = "Years", ylab = "Amount in CZK")
  })
  
  # CZECH INFLATION
  library(rvest)
  library(dplyr)
  link = "https://www.czso.cz/csu/czso/mira_inflace"
  inf = read_html(link)
  inf_table <- inf %>% html_nodes("table") %>% .[2] %>% 
    html_table(fill = TRUE) %>% .[[1]]
  
  inf_table <- inf_table[7:28,2:13]
  inf_vector <- as.vector(t(inf_table))
  inf_vector <- as.numeric(gsub(",", ".", inf_vector))
  
  output$inflation <- renderPlot ({
    Inflation <- ts(inf_vector, start = c(2000, 1),frequency = 12) # year month
    plot(Inflation, lwd = 2, col = "red", main = "Inflation in the Czech Republic")
  })
  
  output$current <- renderTable ({
    Inflation <- ts(inf_vector, start = c(2000, 1),frequency = 12) # ts
    dmn <- list(month.abb, unique(floor(time(Inflation)))) # df
    current <- as.data.frame(t(matrix(Inflation, 12, dimnames = dmn))) # df
    current <- cbind(Year = rownames(current), current) # index
    rownames(current) <- 1:nrow(current) # index
    current
  })
  
  output$arima <- renderPlot ({
    library(tseries)
    library(forecast)
    Inflation <- ts(inf_vector, start = c(2000, 1),frequency = 12) # pred
    Inflation <- na.remove(Inflation)
    arima <- Arima(Inflation, 
                   order = c(3,1,1), 
                   seasonal = c(1,0,0))
    arima <- forecast(arima, h = input$select_month, level=c(0,0))
    plot(arima, lwd = 2, xlab = "Time", ylab = "Inflation")
  })
  
  output$ann <- renderPlot({
    library(tseries)
    library(forecast)
    Inflation <- ts(inf_vector, start = c(2000, 1),frequency = 12) # pred
    Inflation <- na.remove(Inflation) 
    fit <- nnetar(Inflation)
    ann <- forecast(fit, h = input$select_month, PI = F) # interval confidence
    plot(ann, lwd = 2, xlab = "Time", ylab = "Inflation")
  })
}