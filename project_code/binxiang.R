#---------------------------------
#    Basic Questions HW1
#---------------------------------
# Libraries loading 
library(RODBC)
library(ggplot2)

# Link to MySQL server 
db = odbcConnect("MySQL", uid="root") # change if needed with name of your ODBC DNS

#-    How much money is collected every year?


query1 ="SELECT YEAR(ActDate) as Year, SUM(Amount) as Total_amount
          FROM charity.acts
          GROUP BY Year"

data1 = sqlQuery(db,query1)


#-    How many donations 

#-     Evolution of average amount per donation for DO and PA through the different years 

query2 = "SELECT YEAR(ActDate) as Year, ActType, AVG(Amount) as Avg_amount
          FROM charity.acts 
          GROUP BY Year, ActType"

data2 = sqlQuery(db,query2)
plot2 = ggplot(data = data2, aes(x=Year, y=Avg_amount,col=ActType)) + geom_point() + geom_line() + 
        labs(title = 'Evolution of the average amount per donation',y = 'Average amount per donation') +
        xlim(c(2002,2013)) + ylim(c(0,max(data2$Avg_amount)+10))
print(plot2)





#-    Evolution of total number of donations for DO and PA through the different years
# we will first estimate the number of donations (DO and PA) for December 2013 by taking
# the values of the previous year, there are of course more complex methods

query3 = "SELECT * FROM (
          SELECT YEAR(ActDate) as Year, MONTH(ActDate) as Month, ActType, COUNT(Amount) as Nb
          FROM charity.acts 
          GROUP BY Year, Month,ActType) A
          WHERE A.Year = 2012 AND A.Month = 12"
data3 = sqlQuery(db,query3)




# Now we query the data grouping by year and ActType
query4 = "
          SELECT YEAR(ActDate) as Year, ActType, COUNT(Amount) as Nb
          FROM charity.acts 
          GROUP BY Year, ActType
         "
data4 = sqlQuery(db,query4)
# add data for 2013 with the estimate of the number for december 2013
data4[data4$Year==2013&data4$ActType=='DO','Nb'] = data4[data4$Year==2013&data4$ActType=='DO','Nb'] + 
                                                        data3[data3$ActType=='DO','Nb']
data4[data4$Year==2013&data4$ActType=='PA','Nb'] = data4[data4$Year==2013&data4$ActType=='PA','Nb'] + 
                                                        data3[data3$ActType=='PA','Nb']


plot4 = ggplot(data = data4, aes(x=Year, y=Nb,col=ActType)) + geom_point() + geom_line() + 
  labs(title = 'Evolution of the total number of donations',y = 'Number of donations') +
  xlim(c(2002,2013)) + ylim(c(0,max(data4$Nb)+10))
print(plot4)




#- average amount of donations for each month over the different years

query5 = "
          SELECT MONTH(ActDate) as Month, ActType, AVG(Amount) as Avg_amount
          FROM charity.acts 
          GROUP BY Month,ActType"


data5 = sqlQuery(db,query5)

plot5 = ggplot(data = data5,aes(x=Month,y=Avg_amount,color=ActType)) + geom_point() + geom_line() +
  labs(title = 'Average amount per donation by month',y = 'Average amount per donation') +
  xlim(c(0,13)) + ylim(c(0,max(data5$Avg_amount)+5))
#
print(plot5)





#- average number of donations for each month

query6 = "SELECT A.Month, A.ActType, AVG(A.Nb) as Avg_Nb
          FROM
          (SELECT YEAR(ActDate) as Year, MONTH(ActDate) as Month, ActType, COUNT(Amount) as Nb
          FROM charity.acts 
          GROUP BY Year,Month,ActType) A 
          GROUP BY A.Month, A.ActType "
data6 = sqlQuery(db,query6)
plot6 = ggplot(data = data6,aes(x=Month,y=Avg_Nb,color=ActType)) + geom_line() + geom_point()+
  labs(title = 'Average number of donations by month',y = 'Average number of donations') +
  xlim(c(0,13)) + ylim(c(0,max(data6$Avg_Nb)+5))

print(plot6)





#- average amount per donation for each day of the week 

query7 = "
          SELECT DAYOFWEEK(ActDate) as Day, ActType, AVG(Amount) as Avg_amount
          FROM charity.acts 
          GROUP BY Day,ActType"
data7 = sqlQuery(db,query7)


plot7 = ggplot(data = data7,aes(x=Day,y=Avg_amount,color=ActType)) + geom_line() + geom_point()+
  labs(title = 'Average amount per donation by day of week',y = 'Average amount per donation') +
  ylim(c(0,max(data7$Avg_amount)+5)) +scale_x_discrete(limit = c('Sun','Mon','Tue','Wed','Thu','Fri','Sat'))
print(plot7)





#- average number of donation for each day of the week
query8 = "SELECT A.Day, A.ActType, AVG(A.Nb) as Avg_Nb
          FROM
          (SELECT YEAR(ActDate) as Year, DAYOFWEEK(ActDate) as Day, ActType, COUNT(Amount) as Nb
          FROM charity.acts 
          GROUP BY Year,Day,ActType) A 
          GROUP BY A.Day, A.ActType "

data8 = sqlQuery(db,query8)
plot8 = ggplot(data = data8,aes(x=Day,y=Avg_Nb,color=ActType)) + geom_line() + geom_point()+
  labs(title = 'Average number of donations by day of week',y = 'Average number of donations') +
  ylim(c(0,max(data8$Avg_Nb)+5)) +scale_x_discrete(limit = c('Sun','Mon','Tue','Wed','Thu','Fri','Sat'))
print(plot8)


