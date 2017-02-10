#---------------------------------
#    Some other Questions
#---------------------------------
# Libraries loading 
library(RODBC)
library(ggplot2)

# Link to MySQL server 
db = odbcConnect("mysql_server_64", uid="root") # change if needed with name of your ODBC DNS

# 1.    How much money is collected every year? -------------------------------------------------

query1 ="SELECT YEAR(ActDate) as Year, ActType, SUM(Amount) as Total_amount
          FROM charity.acts
          GROUP BY Year, ActType"

data1temp = sqlQuery(db,query1)
head(data)

# Complete years with zeros
for (year in 2003:2005){
    data1temp = rbind(data1temp, c(year, "PA", 0))
}
data1 = data1temp[order(data1temp$Year),]
data1$Total_amount = as.numeric(data1$Total_amount)

# 2013 basic prediction with december 2012 data
query1bis = "SELECT Year, ActType, Total_amount FROM (
SELECT YEAR(ActDate) as Year, MONTH(ActDate) as Month, ActType, SUM(Amount) as Total_amount
FROM charity.acts 
GROUP BY Year, Month,ActType) A
WHERE A.Year = 2012 AND A.Month = 12"
data1bis= sqlQuery(db,query1bis)

datapred = data1
datapred[c(nrow(data1)-1,nrow(data1)),3] = data1[c(nrow(data1)-1,nrow(data1) ),3] + data1bis[,3]

# Plot the results
gr1 = ggplot(data = data1, aes(x = Year, y = Total_amount)) +
    geom_bar(data = data1, stat = "identity", alpha = 0.4, position="dodge", aes(fill = ActType))+
    labs(title = "Total amount of donations through the years") +
    geom_bar(data = datapred, stat = "identity", position = "dodge", alpha = 0.3, aes(fill = ActType))+
    labs(y = "Total Amount (thousands)")+
    scale_y_continuous(labels = list(0, 200, 400, 600, 800))
print(gr1)


# 2.    Amount repartitions ----------------------------------------------------------------------

query2 ='SELECT ActType, Amount
         FROM charity.acts'

data2 = sqlQuery(db,query2)
head(data2)

PAs = as.data.frame(cut(data2$Amount[data2$ActType=='PA'],breaks = seq(0, 100, by = 5)))
colnames(PAs)=c('Amounts')
PAs['ActType'] = 'PA'
DOs = as.data.frame(cut(data2$Amount[data2$ActType=='DO'], breaks = seq(0, 100, by = 5)))
colnames(DOs)=c('Amounts')
DOs['ActType'] = 'DO'
data2= rbind(PAs, DOs)

# Minor correction for aestethical purposes
data2 = rbind(data2, c("(70,75]", "PA"))
data2 = rbind(data2, c("(80,85]", "PA"))

# Customize labels
xlabels = rep("",21)
for (i in 1:20){
    a = paste("]",(i-1)*5,",",i*5,"]", sep = "")
    xlabels[i] = a
}
xlabels[21] = ">100"

# Plot the results
gr2 = ggplot(data= data2, aes(x=Amounts, fill = ActType))+
    geom_histogram(alpha=.7, stat="count", position="dodge")+
    scale_x_discrete(labels = xlabels)+
    labs(title = "Number of donations by amount",y= "Number of donations", x= "Amount")
print(gr2)

# 2.    Pareto Rule ------------------------------------------------------------------------------

# ---- DO ----
query3 ='SELECT ContactId as Donators, SUM(Amount) as Sum_of_donations
         FROM charity.acts
         WHERE ActType LIKE "DO"
         GROUP BY 1
         ORDER BY 2 DESC'

data3 = sqlQuery(db,query3)
dim(data3)

data3$Donators = seq(0,1, length.out = nrow(data3))
data3$Sum_of_donations = as.numeric(data3$Sum_of_donations/data3$Sum_of_donations[1])
head(data3)


# Plot the results
gr3 = ggplot(data = data3, aes(x = Donators, y = Sum_of_donations, colour = "Sum of donations")) +
    geom_line(alpha = 0.7, size = 1) +
    geom_line(data = data3,alpha = 0.7, size = 1, aes(colour = "Cumulative sum", x= Donators, y=cumsum(Sum_of_donations)/sum(data3$Sum_of_donations)))+ 
    geom_vline(xintercept = .2, colour="#0e492d", linetype = "longdash") +
    geom_hline(yintercept = .8, colour="#0e492d", linetype = "longdash") +
    scale_colour_discrete("")+
    scale_x_continuous(breaks = c(0,.2,.4,.6,.8,1))+
    scale_y_continuous(breaks = c(0,.2,.4,.6,.8,1))+
    labs(title = "Contribution of donators to the overall donations",  y = "Ratio of overall donations")

print(gr3)

# ---- PA ----

query4 ='SELECT ContactId as Donators, SUM(Amount) as Sum_of_donations
         FROM charity.acts
         WHERE ActType LIKE "PA"
         GROUP BY 1
         ORDER BY 2 DESC'

data4 = sqlQuery(db,query4)
dim(data4)

data4$Donators = seq(0,1, length.out = nrow(data4))
data4$Sum_of_donations = as.numeric(data4$Sum_of_donations/data4$Sum_of_donations[1])
head(data4)


# Plot the results
gr4 = ggplot(data = data4, aes(x = Donators, y = Sum_of_donations, colour = "Sum of direct debits")) +
    geom_line(alpha = 0.7, size = 1) +
    geom_line(data = data4,alpha = 0.7, size = 1, aes(colour = "Cumulative sum", x= Donators, y=cumsum(Sum_of_donations)/sum(data4$Sum_of_donations)))+ 
    geom_vline(xintercept = .2, colour="#0e492d", linetype = "longdash") +
    geom_hline(yintercept = .8, colour="#0e492d", linetype = "longdash") +
    scale_colour_discrete("")+
    scale_x_continuous(breaks = c(0,.2,.4,.6,.8,1))+
    scale_y_continuous(breaks = c(0,.2,.4,.6,.8,1))+
    labs(title = "Contribution of donators to the overall direct debits", y = "Ratio of overall direct debits")


print(gr4)

