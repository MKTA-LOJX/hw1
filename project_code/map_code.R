library(RODBC)
db = odbcConnect("MySQL", uid="root")

acts = sqlQuery(db,"SELECT * FROM charity.acts LIMIT 10")
actions = sqlQuery(db,"SELECT * FROM charity.actions LIMIT 10")
contacts = sqlQuery(db,"SELECT * FROM charity.contacts LIMIT 10")

query1 ="SELECT A.ContactId, A.ActType, A.PaymentType, YEAR(A.ActDate) as Year, A.Amount,B.ZipCode, SUBSTRING(B.ZipCode, 1, CHAR_LENGTH(B.ZipCode) - 3) as Dep
          FROM charity.acts A 
          JOIN charity.contacts B
          ON A.ContactId = B.ContactId"

query2 = paste("SELECT A.Dep,A.ActType,AVG(Amount) as Avg_amount, COUNT(Amount) as Nb
          FROM

          (",query1,") A
          
          GROUP BY A.Dep,A.ActType")

query3 = paste("SELECT A.Dep,A.ActType,SUM(Amount)/COUNT(Amount) as MntparDonc,SUM(Amount) as Tot_amount, COUNT(Amount) as Nb
          FROM

          (",query1,") A
          WHERE A.Year=2013
          GROUP BY A.Dep,A.ActType")

res1 = sqlQuery(db,query1)
res2_tot = sqlQuery(db,query2)
res2_2013 = sqlQuery(db,query3)


library(maps)
library(ggplot2)
library(maptools)
library(RColorBrewer)


departements<-readShapeSpatial("Cours3A/MSc/MarketingAnalytics/hw1/map_france/DEPARTEMENT.shp",
                               proj4string=CRS("+proj=longlat"))
plot(departements)
plot(departements,col=as.numeric(departements$CODE_REG))
res2_2013_DO = res2_2013[res2_2013$ActType == 'DO',]
res2_2013_PA = res2_2013[res2_2013$ActType == 'PA',]
df = match(departements$CODE_DEPT,res2_2013_PA$Dep)
couleurs<-res2_2013_PA$MntparDonc[df]/max(res2_2013_PA$MntparDonc)
couleurs[is.na(couleurs)] <- 0
plot(departements,col=gray(1-couleurs)) #rgb(1-couleurs, green=0, blue=0))#

my_palette <- colorRampPalette("gray")(n = length(unique(couleurs)))

legend('topleft',col = gray(),legend = c(17.5,'','',1160))

