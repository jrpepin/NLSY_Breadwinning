*-------------------------------------------------------------------------------
* BREADWINNER PROJECT - NLSY97 Component
* nlsy97_hh60_stata_pred.do
* Joanna Pepin
*-------------------------------------------------------------------------------

********************************************************************************
* Setup the log file
********************************************************************************
local logdate = string( d(`c(current_date)'), "%dCY.N.D" ) 	// create a macro for the date

local list : dir . files "$logdir/*nlsy97_hh60_stata_pred_*.log"	// Delete earlier versions of the log
foreach f of local list {
    erase "`f'"
}

log using "$logdir/nlsy97_hh60_stata_pred_`logdate'.log", t replace

di "$S_DATE"

********************************************************************************
* DESCRIPTION
********************************************************************************
* This file predictes breadwinning status relative to the specific duration of motherhood

* This data used in this file were created from the R script nlsy97_04_hhearn, 
* located in the project directory.

********************************************************************************
* Open and prep the data
********************************************************************************
clear
set more off

use 	"stata/NLSY97_processed.dta", clear
fre year // Make sure the data includes all survey years (1997 - 2017)

keep if firstbirth==1 // didn't drop in R already
********************************************************************************
* Generate basic descriptives
********************************************************************************
tab time 		hhe60, row
tab marst 		hhe60, row
tab age_birth 	hhe60, row

table time marst, contents(mean hhe60) col	// BW by duration of motherhood & marst
table age_birth marst, contents(mean hhe60) // BW by age at first birth & marst


// Select only observations since first birth
keep if firstbirth==1 			// diff from before
drop firstbirth 				// this variable has no variation now
drop age_birth age marst		// These variables get in the way for this analysis

********************************************************************************
* Create lagged measures of breadwinning
********************************************************************************
* We only need one lag for transtion into breadwinning and measures of whether 
* any breadwinning up to this point in time

// Reshape the data
keep  year hhe60 PUBID_1997 time wt1997
reshape wide year hhe60, i(PUBID_1997) j(time)

// Set the first lag to 0 because it is not possible to be a breadwinning mother
// before being a mother.
gen hh50_minus1_0=0

// Create the lagged measures
forvalues t=1/9{
    local s=`t'-1
    gen hhe60_minus1_`t'=hhe60`s' 
}

forvalues t=2/9{
    local r=`t'-2
    gen hhe60_minus2_`t'=hhe60`r' 
}

forvalues t=3/9{
    local u=`t'-3
    gen hhe60_minus3_`t'=hhe60`u' 
}

forvalues t=4/9{
    local v=`t'-4
    gen hhe60_minus4_`t'=hhe60`v' 
}

forvalues t=5/9{
    local v=`t'-5
    gen hhe60_minus5_`t'=hhe60`v' 
}

forvalues t=6/9{
    local v=`t'-6
    gen hhe60_minus6_`t'=hhe60`v' 
}

forvalues t=7/9{
    local v=`t'-7
    gen hhe60_minus7_`t'=hhe60`v' 
}

forvalues t=8/9{
    local v=`t'-8
    gen hhe60_minus8_`t'=hhe60`v' 
}

forvalues t=9/9{
    local v=`t'-9
    gen hhe60_minus9_`t'=hhe60`v' 
}

// Create indicators for whether R has been observed as a 
// breadwinning mother at any previous duration of motherhood

gen prevbreadwon0=0 // can't have previously breadwon and duration 0

forvalues t=1/9 {
	gen prevbreadwon`t'=0
	local s=`t'-1
    * loop over all earlier duratons looking for any breadwinning
	forvalues u=0/`s' { 
		replace prevbreadwon`t'=1 if hhe60`u'==1
	}
}

reshape long year hhe60 hhe60_minus1_ hhe60_minus2_ hhe60_minus3_ hhe60_minus4_ ///
             hhe60_minus5_ hhe60_minus6_ hhe60_minus7_ hhe60_minus8_  ///
			 hhe60_minus9_ prevbreadwon, i(PUBID_1997) j(time)

* clean up observations created because reshape creates some number of observations for each (PUBID_1997)
drop if missing(year)

********************************************************************************
* B1. Estimates of transitions into breadwinning (at each duration of motherhood)
********************************************************************************

preserve
forvalues t = 0/9 {
	drop if hhe60_minus1_ == 1
	tab hhe60 if time == `t'

	}
restore

********************************************************************************
* B2. Risk of entering breadwinning, censoring on previous breadwinning
********************************************************************************
// Create ever breadwinning prior to this duration variable

bysort PUBID_1997 (time) : gen everbw = sum(hhe60_minus1_) // 
replace everbw = 1 if everbw >= 1 

tab time everbw, row

preserve
forvalues t = 0/9 {
	drop if prevbreadwon == 1 
	tab hhe60 if time == `t' [fweight=wt1997]
	}
restore

********************************************************************************
* B3. Proportion breadwinning at each duration of motherhood that have previously breadwon
********************************************************************************
// Create a lagged ever bw variable (so current bw doesn't count)
*sort PUBID_1997 time 
*by PUBID_1997: gen ebwlag = everbw[_n-1]

forvalues t = 1/9 {
	tab everbw hhe60 if time ==`t', col
	}

table time prevbreadwon [fweight=wt1997], contents(mean hhe60) col

********************************************************************************
* Create lifetable
********************************************************************************
// Tell Stata the format of the survival data

* STS wants the time variable to start at 1
replace time=time+1 

stset time, id(PUBID_1997) failure(hhe60==1)

* why does sts think we start with 2371 observations unweighted. It's 1678.
* The problem is missing values for hhe60
sts list

sort PUBID_1997
list PUBID_1997 time year hhe60 _st _d _t _t0 in 1/20

stdescribe
stsum
stvary

ltable _t _d
ltable _t _d, hazard
ltable _t _d, failure

********************************************************************************
* Predict breadwinning
********************************************************************************
logit hhe60 hhe60_minus1_ i.time
logit hhe60 hhe60_minus1_ hhe60_minus2_ i.time
logit hhe60 hhe60_minus1_ hhe60_minus2_ hhe60_minus3_ i.time
logit hhe60 hhe60_minus1_ hhe60_minus2_ hhe60_minus3_ hhe60_minus4_ i.time

log close
