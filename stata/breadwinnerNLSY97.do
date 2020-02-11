*-------------------------------------------------------------------------------
* BREADWINNER PROJECT - NLSY97 Component
* breadwinnnerNLSY97.do
* Joanna Pepin
*-------------------------------------------------------------------------------
* The goal of these files is to create estimates of breadwinning in order to
* better account for repeat breadwinning using the SIPP

********************************************************************************
* A. ENVIRONMENT
********************************************************************************
* There are two scripts users need to run before importing the data. 
* First, create a personal setup file using the setup_example.do script as a template
* and save this file in the base project directory.
* Second, run the setup_breadwinnerNLSY97_environment script to set the project filepaths and macros.

// The current directory is assumed to be the base project directory.
// change to the directory before running breadwinnerNLSY97.do
*	cd "C:\Users\Joanna\Dropbox\Repositories\NLSY97_Breadwinning" 

// Run the setup script
	do "stata/setup_breadwinnerNLSY97_environment"
	
* The logs for these files are generated within each .do files.

********************************************************************************
* B. Risk of entering breadwinning for the first 10 years of motherhood
********************************************************************************
	
// Breadwinning estimates at the 50% threshold
    do "stata/nlsy97_hh50_risk.do"
	
// Breadwinning estimates at the 60% threshold
    do "stata/nlsy97_hh60_risk.do"
	
********************************************************************************
* C. Predict breadwinning status relative to the specific duration of motherhood
********************************************************************************
*?*?* JP : This is what we did before. Is that the same as censored breadwinning (B2)?

// Breadwinning estimates at the 50% threshold
    do "stata/nlsy97_hh50_pred.do"

// Breadwinning estimates at the 60% threshold
    do "stata/nlsy97_hh60_pred.do"