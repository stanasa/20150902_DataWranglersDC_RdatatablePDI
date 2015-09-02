#' Introduction to data.table
#' Author: Serban Tanasa
#' Email: stanasa 'at' sunstonescience.com
#' Date: 2015-09-02

rm(list=ls());gc()
#Load data.table (quietly)
suppressMessages(require(data.table))
suppressMessages(require(microbenchmark))


setwd("/Data")
#devtools::install_github("Rdatatable/data.table")  #required for uniqueN()

##############
#   fread()  #
##############

dates <- fread("Date_Dimension.csv")
names(dates)

## setkey created indices for the table, will display ordered
setkey(dates, date_id)

# fread with shell commands:
# Under Windows requires cygwin installed and in system PATH
Sundates <-  fread("grep 'Sunday' Date_Dimension.csv")
names(Sundates)
# grep will skip the header line, so we lose header information

#Automatically restricts printing to screen if table > 100 rows
dates

#Return specified rows (i operation)
dates[8:12]
#Return specified rows (i operation with .N)
dates[(.N-5):.N]
identical(tail(dates),dates[(.N-5):.N])

# fread with select:
Sunjustdates <-  fread("grep 'Sunday' Date_Dimension.csv",
                       select="V2")
#Using `:=` (j operation) and chaining
Sunjustdates[, dateform :=  as.Date(V2) ][,V2 := NULL]
#Setting a key
setkey(Sunjustdates, dateform)
Sunjustdates
#Use of `between` on dates:
Sunjustdates[between(dateform, "2015-09-02","2015-12-31") , ]
#combining i and j operations:
Sunjustdates[between(dateform, "2015-09-02","2015-12-31") , .N ]

# fread on URLs:
mydat <- fread("http://www.stats.ox.ac.uk/pub/datasets/csb/ch11b.dat")
head(mydat)

  ################
 # Binary sort  #
################

set.seed(2L)
N = 2e8L #200,000,000 !  
#Maybe precompile this for presentation?
DT = data.table(x = sample(letters, N, TRUE), 
                y = sample(1000L, N, TRUE), 
                val=runif(N), key = c("x", "y"))
print(object.size(DT), units="Mb")
# 381.5 Mb
key(DT)
DT


#t0 <- system.time(ans1 <- DT[x == "g" & y == 877L])
#t0
t1 <- microbenchmark(ans1 <- DT[x == "g" & y == 877L], times=1, unit="ms")
t1
#    user  system elapsed 
#   8.49    0.55    9.05 
head(ans1)
#    x   y       val
# 1: g 877 0.3946652
# 2: g 877 0.9424275
# 3: g 877 0.7068512
# 4: g 877 0.6959935
# 5: g 877 0.9673482
# 6: g 877 0.4842585
dim(ans1)
# [1] 761   3
#Now let's try to subset by using keys.

## (2) Subsetting using keys
t2 <- microbenchmark(ans2 <- DT[.("g", 877L)], times=1, unit="ms")
t2
#    user  system elapsed 
#   0.001   0.000   0.002
head(ans2)
#    x   y       val
# 1: g 877 0.3946652
# 2: g 877 0.9424275
# 3: g 877 0.7068512
# 4: g 877 0.6959935
# 5: g 877 0.9673482
# 6: g 877 0.4842585
dim(ans2)
# [1] 761   3

identical(ans1$val, ans2$val)

rm(list=ls());gc()








##Let's get some more interesting data:
# http://www.transtats.bts.gov/DL_SelectFields.asp?Table_ID=236&DB_Short_Name=On-Time
setwd("/Data/OnTime")
#list files with pattern matching
files <- list.files(pattern=".*_2015_[1-6]\\.csv")

#bulkload a bunch of files and rbind them with data.table speedup
flightdata <- rbindlist(lapply(files, fread))
dim(flightdata)
names(flightdata)
setkey( flightdata, FlightDate, AirlineID, OriginCityName, Carrier )
flightdata[, .(min(FlightDate),max(FlightDate))]
flightdata[, sort(unique(Carrier))]
flightdata[, sum(ArrDelay, na.rm = T)]
flightdata[, sum(ArrDelay, na.rm = T), by=.(Carrier)]
#gah, codes?
#load lookup table, ignore early arrivals (focus on the negative)
carriernames <- fread("L_UNIQUE_CARRIERS.csv")
carriernames
#We only have a small subset of the data, airlines that report delay info.
setnames(carriernames, c("Carrier","FullCarrierName"))
setkey(carriernames, Carrier)
flightdata <- merge(flightdata, carriernames, by="Carrier")
flightdata[, .(TotalDelay=sum(ArrDelayMinutes, na.rm=T)), by=FullCarrierName][order(-TotalDelay),]
flightdata[, .(AvgDelay=mean(ArrDelayMinutes, na.rm=T)), by=FullCarrierName][order(-AvgDelay),]

