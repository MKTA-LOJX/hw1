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

# Plot the results
gr = ggplot(data = data1, aes(x = Year, y = Total_amount, fill = ActType)) +
    geom_bar(stat = "identity", alpha = 0.7, position="dodge")
print(gr)


# 2.    Amount repartitions ---------------------------

query3 ='SELECT ActType, Amount
         FROM charity.acts'

data3 = sqlQuery(db,query3)
head(data3)

PAs = as.data.frame(cut(data3$Amount[data3$ActType=='PA'],breaks = seq(0, 100, by = 5)))
colnames(PAs)=c('Amounts')
PAs['ActType'] = 'PA'
DOs = as.data.frame(cut(data3$Amount[data3$ActType=='DO'], breaks = seq(0, 100, by = 5)))
colnames(DOs)=c('Amounts')
DOs['ActType'] = 'DO'
data3= rbind(PAs, DOs)

# Minor correction for aestethical purposes
data3 = rbind(data3, c("(70,75]", "PA"))
data3 = rbind(data3, c("(80,85]", "PA"))

# Plot the results
gr = ggplot(data= data3, aes(x=Amounts, fill = ActType))+
    geom_histogram(alpha=.7, stat="count", position="dodge")
print(gr)