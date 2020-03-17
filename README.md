# Decline And Retrenchment Replication Data
Stata code and data for replicating analyses presented in: Atkinson, Douglas B. and George W. Williford. 2016. "Should We Stay or Should We Go? Exploring the Outcomes of Great Power Retrenchment." Research and Politics 3(4).

## Project Description
Within foreign policy and academic circles in the United States and other western countries, retrenchment has become an increasingly controversial topic. In spite of the increased attention, there have been few empirical studies that rigorously examine the outcomes of great power retrenchment. In this paper, we seek to fill this gap by performing a quantitative analysis of great power retrenchment outcomes from 1870–2007. Counter to the retrenchment pessimists’ expectations, we find that retrenchment leads to relatively positive outcomes for declining states. States that choose to retrench experience shorter periods of economic decline and are less likely to be the target of predatory conflict initiation.

## Methods Used
- Logistic Regression
- Survival Analysis
- Multiple Imputation (used to impute missing data). 

## Software Used
Analysis was conducted using Stata version 13.1.

## File Descriptions
- AtkinsonWillifordRandP.pdf - a copy of the published article.
- RetrenchModelsRRFinal20200316.do - Do-file to replicate logistic regression and survival analysis presented in the article
- RetrenchDataDoFile.do - Stata do-file used for data merging and management and for conducting multiple imputation
- raw data.zip - zip file containing datasets used by RetrenchDataDoFile.do
- Retrench1yr.dta - Dataset used to conduct analysis of data using a one-year threshold for whether states have recovered their power relative to other states. Output by RetrenchDataDoFile.do
- Retrench5yr.dta - Dataset used to conduct analysis of data using a five-year threshold for whether states have recovered their power relative to other states. Output by RetrenchDataDoFile.do
