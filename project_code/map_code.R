library(RODBC)
library(maps)
library(ggplot2)
library(maptools)

# To plot the map, you need to use the france department shapes files included in the zip

db = odbcConnect("MySQL", uid="root")

querytemp ="SELECT A.ContactId, A.ActType, A.PaymentType, YEAR(A.ActDate) as Year, A.Amount,B.ZipCode, SUBSTRING(B.ZipCode, 1, CHAR_LENGTH(B.ZipCode) - 3) as Dep
          FROM charity.acts A 
          JOIN charity.contacts B
          ON A.ContactId = B.ContactId"

query1 = paste("SELECT A.Dep,A.ActType,AVG(Amount) as Avg_amount
          FROM

          (",querytemp,") A
          
          WHERE A.Dep IS NOT NULL
          GROUP BY A.Dep,A.ActType")


# France Map with the average amount per donation for each department
data1 = sqlQuery(db,query1)

## Load map 
departements<-readShapeSpatial("./map_france/DEPARTEMENT.shp", proj4string=CRS("+proj=longlat"))

##### plot for DO #####
data1_DO = data1[data1$ActType == 'DO',]

match1 = match(departements$CODE_DEPT,data1_DO$Dep) # match department and data
# attribute colors for each department depending on avg amount
# white to black (small to big values)
colors_DO <-data1_DO$Avg_amount[match1]/max(data1_DO$Avg_amount)
# assign 0 when a department is not present 
colors_DO[is.na(colors_DO)] <- 0
#plot
plot(departements,col=gray(1-colors_DO),main='Average amount per donation (DO) by "département"')


##### plot for PA #####
data1_PA = data1[data1$ActType == 'PA',]

match2 = match(departements$CODE_DEPT,data1_PA$Dep) # match department and data
# attribute colors for each department 
# white to black (small to big values)
colors_PA <-data1_PA$Avg_amount[match2]/max(data1_PA$Avg_amount)
# assign 0 when a department is not present 
colors_PA[is.na(colors_PA)] <- 0
plot(departements,col=gray(1-colors_PA),main='Average amount per donation (PA)  by "département"')



