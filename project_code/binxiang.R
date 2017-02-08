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

#- Distribution of average amount of donations for each month over the different years

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


#- Distribution of average number of donations for each month

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
# Lets separate the data in each year (2003-2013)
acts2003 = acts[acts$ActDate >= as.Date("2003-01-01", "%Y-%m-%d") & acts$ActDate <= as.Date("2003-12-31", "%Y-%m-%d"), ]
acts2004 = acts[acts$ActDate >= as.Date("2004-01-01", "%Y-%m-%d") & acts$ActDate <= as.Date("2004-12-31", "%Y-%m-%d"), ]
acts2005 = acts[acts$ActDate >= as.Date("2005-01-01", "%Y-%m-%d") & acts$ActDate <= as.Date("2005-12-31", "%Y-%m-%d"), ]
acts2006 = acts[acts$ActDate >= as.Date("2006-01-01", "%Y-%m-%d") & acts$ActDate <= as.Date("2006-12-31", "%Y-%m-%d"), ]
acts2007 = acts[acts$ActDate >= as.Date("2007-01-01", "%Y-%m-%d") & acts$ActDate <= as.Date("2007-12-31", "%Y-%m-%d"), ]
acts2008 = acts[acts$ActDate >= as.Date("2008-01-01", "%Y-%m-%d") & acts$ActDate <= as.Date("2008-12-31", "%Y-%m-%d"), ]
acts2009 = acts[acts$ActDate >= as.Date("2009-01-01", "%Y-%m-%d") & acts$ActDate <= as.Date("2009-12-31", "%Y-%m-%d"), ]
acts2010 = acts[acts$ActDate >= as.Date("2010-01-01", "%Y-%m-%d") & acts$ActDate <= as.Date("2010-12-31", "%Y-%m-%d"), ]
acts2011 = acts[acts$ActDate >= as.Date("2011-01-01", "%Y-%m-%d") & acts$ActDate <= as.Date("2011-12-31", "%Y-%m-%d"), ]
acts2012 = acts[acts$ActDate >= as.Date("2012-01-01", "%Y-%m-%d") & acts$ActDate <= as.Date("2012-12-31", "%Y-%m-%d"), ]
acts2013 = acts[acts$ActDate >= as.Date("2013-01-01", "%Y-%m-%d") & acts$ActDate <= as.Date("2013-12-31", "%Y-%m-%d"), ]

amountperyear = c(sum(acts2003$Amount), sum(acts2004$Amount), sum(acts2005$Amount), sum(acts2006$Amount), sum(acts2007$Amount), sum(acts2008$Amount), sum(acts2009$Amount), sum(acts2010$Amount), sum(acts2011$Amount), sum(acts2012$Amount), sum(acts2013$Amount))

# Plot the results
barplot(amountperyear, main = "Amount collected per year", xlab = "Year", ylab = "Amount", type = "b", names.arg =seq(2003, 2013))

# Total money collected
sum(amountperyear)

# Mean money collected per year (NOT taking into account the not-complete years)
mean(amountperyear[2:10])

#-    How much money is collected through classic donations (ActType=’DO’) and automatic deductions (ActType=’PA’)?

# Seperating both donation types
actsDO = acts[acts$ActType == "DO", ]
actsPA = acts[acts$ActType == "PA", ]

# Total money collected through classic donations (ActType=’DO’)
sum(actsDO$Amount)

# Total money collected through automatic deductions (ActType=’PA’)
sum(actsPA$Amount)

# Decomposition per year for classic donations (ActType=’DO’)
acts2003_DO = acts2003[acts2003$ActType == "DO", ]
acts2004_DO = acts2004[acts2004$ActType == "DO", ]
acts2005_DO = acts2005[acts2005$ActType == "DO", ]
acts2006_DO = acts2006[acts2006$ActType == "DO", ]
acts2007_DO = acts2007[acts2007$ActType == "DO", ]
acts2008_DO = acts2008[acts2008$ActType == "DO", ]
acts2009_DO = acts2009[acts2009$ActType == "DO", ]
acts2010_DO = acts2010[acts2010$ActType == "DO", ]
acts2011_DO = acts2011[acts2011$ActType == "DO", ]
acts2012_DO = acts2012[acts2012$ActType == "DO", ]
acts2013_DO = acts2013[acts2013$ActType == "DO", ]

amountperyear_DO = c(sum(acts2003_DO$Amount), sum(acts2004_DO$Amount), sum(acts2005_DO$Amount), sum(acts2006_DO$Amount), sum(acts2007_DO$Amount), sum(acts2008_DO$Amount), sum(acts2009_DO$Amount), sum(acts2010_DO$Amount), sum(acts2011_DO$Amount), sum(acts2012_DO$Amount), sum(acts2013_DO$Amount))

# Plot the results
barplot(amountperyear_DO, main = "Amount collected per year - DO", xlab = "Year", ylab = "Amount", type = "b", names.arg =seq(2003, 2013))

# Decomposition per year for automatic deductions (ActType=’PA’)
acts2003_PA = acts2003[acts2003$ActType == "PA", ]
acts2004_PA = acts2004[acts2004$ActType == "PA", ]
acts2005_PA = acts2005[acts2005$ActType == "PA", ]
acts2006_PA = acts2006[acts2006$ActType == "PA", ]
acts2007_PA = acts2007[acts2007$ActType == "PA", ]
acts2008_PA = acts2008[acts2008$ActType == "PA", ]
acts2009_PA = acts2009[acts2009$ActType == "PA", ]
acts2010_PA = acts2010[acts2010$ActType == "PA", ]
acts2011_PA = acts2011[acts2011$ActType == "PA", ]
acts2012_PA = acts2012[acts2012$ActType == "PA", ]
acts2013_PA = acts2013[acts2013$ActType == "PA", ]

amountperyear_PA = c(sum(acts2003_PA$Amount), sum(acts2004_PA$Amount), sum(acts2005_PA$Amount), sum(acts2006_PA$Amount), sum(acts2007_PA$Amount), sum(acts2008_PA$Amount), sum(acts2009_PA$Amount), sum(acts2010_PA$Amount), sum(acts2011_PA$Amount), sum(acts2012_PA$Amount), sum(acts2013_PA$Amount))

# Plot the results
barplot(amountperyear_PA, main = "Amount collected per year - PA", xlab = "Year", ylab = "Amount", type = "b", names.arg = seq(2003, 2013))

# Plot both together
dat <- rbind(amountperyear_DO, amountperyear_PA)
colnames(dat) = seq(2003, 2013)
rownames(dat) = c("DO", "PA")
barplot(as.matrix(dat), main = "Decomposed amount collected per year", xlab = "Year", ylab = "Amount ($)", col = c("blue","red"))
legend("topleft", fill = c("red", "blue"), legend = c("PA", "DO"), bty = "n")

#-    How many contacts are there in the database? How many donors?

# Unique contact ids in the data base (normally equivalent to the number of contacts in the database)
length(unique(contacts$ContactId)) 

# Lets take a look at the contact ids that are doubled in the contact data base
n_occur <- data.frame(table(contacts$ContactId))
n_occur[n_occur$Freq > 1,]
contacts[contacts$ContactId == 10650, ]
contacts[contacts$ContactId == 98460, ]
contacts[contacts$ContactId == 166900, ]
contacts[contacts$ContactId == 188110, ]
# Its okay, they are just double lines, so we have indeed 24689 unique contacts in the data base. 

# Unique contact ids in the donor data base 
length(unique(acts$ContactId)) 

# Lets just make sure each line in the acts corresponds to a true donation
acts[acts$Amount < 0,]
acts[acts$Amount == 0,]
# Good, so we indeed have 18945 unique donors in our data base. 


#-    How many donors have been active each and every year? 
# Change the list accordingly if we need to check less years
donors_active_each_year = Reduce(intersect, list(acts2003$ContactId, acts2004$ContactId, acts2005$ContactId, acts2006$ContactId, acts2007$ContactId, acts2008$ContactId, acts2009$ContactId, acts2010$ContactId, acts2011$ContactId, acts2012$ContactId, acts2013$ContactId))
length(donors_active_each_year)

#-    Is the average donation amount increasing or decreasing? How much is it?
average_donation = c(mean(acts2003$Amount), mean(acts2004$Amount), mean(acts2005$Amount), mean(acts2006$Amount), mean(acts2007$Amount), mean(acts2008$Amount), mean(acts2009$Amount), mean(acts2010$Amount), mean(acts2011$Amount), mean(acts2012$Amount), mean(acts2013$Amount))
average_donation_DO = c(mean(acts2003_DO$Amount), mean(acts2004_DO$Amount), mean(acts2005_DO$Amount), mean(acts2006_DO$Amount), mean(acts2007_DO$Amount), mean(acts2008_DO$Amount), mean(acts2009_DO$Amount), mean(acts2010_DO$Amount), mean(acts2011_DO$Amount), mean(acts2012_DO$Amount), mean(acts2013_DO$Amount))
average_donation_PA = c(mean(acts2003_PA$Amount), mean(acts2004_PA$Amount), mean(acts2005_PA$Amount), mean(acts2006_PA$Amount), mean(acts2007_PA$Amount), mean(acts2008_PA$Amount), mean(acts2009_PA$Amount), mean(acts2010_PA$Amount), mean(acts2011_PA$Amount), mean(acts2012_PA$Amount), mean(acts2013_PA$Amount))

plot(average_donation_DO, type = 'l', xaxt = "n", col = "blue", ylim=c(0, 140), main = "Average donation amount", ylab = "Amount ($)", xlab = "Year")
lines(average_donation_PA, col = "red")
lines(average_donation, col = "black")
axis(1, 1:11, 2003:2013)
legend("topleft", col = c("black","red", "blue"), legend = c("Total", "PA", "DO"), bty = "n", lty=c(1,1,1))

#-    How many “new” donors were acquired every year?

# First lets create an intermediate function
add_zeros <- function(data){
    new_data = rep(0,length(acts2012$ContactId + 1))
    for (i in 1:length(acts2012$ContactId)){
        if (i <= length(data)){
            new_data[i] = data[i]
        } else if (i > length(data)){
            new_data[i] = 0
        }
    } 
    return(new_data)
}

# And an intermediate database
actsyears = cbind(add_zeros(acts2003$ContactId), add_zeros(acts2004$ContactId),
                  add_zeros(acts2005$ContactId), add_zeros(acts2006$ContactId), 
                  add_zeros(acts2007$ContactId), add_zeros(acts2008$ContactId), 
                  add_zeros(acts2009$ContactId), add_zeros(acts2010$ContactId), 
                  add_zeros(acts2011$ContactId), add_zeros(acts2012$ContactId), 
                  add_zeros(acts2013$ContactId))

# Now for the main function : 
new_donors <- function(year){
    index = year - 2002
    test = actsyears[,1]
    for (i in 1:(index-1)){
        test = list(test, actsyears[,i])
    }
    donors = setdiff(actsyears[,index], Reduce(intersect, test)) # setdiff(x, y) returns the elements of x not present in y
    return(unique(donors))
}
new_donors(2006) # Returns the all new donors adquired in year 2006

num_new_donors <- rep(0, 9)
for (i in 1:10){
    num_new_donors[i] = length(new_donors(i + 2003))
}
length(num_new_donors)

# Plot the results
plot(num_new_donors, main = "New donors per year", type = 'l', xaxt = "n", xlab = "Year", ylab = "Number of new donors")
axis(1, 1:10, 2004:2013)
