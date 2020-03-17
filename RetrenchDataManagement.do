cd "C:/Users/gww17580/Dropbox/Research/3 - Decline and Retrenchment/Stats"
set more off

***Load and reshape GDP per capita data from M&P
*Load data
import excel "./data/raw data/parmac_madisonGDP_updated (2).xlsx", sheet("PerCapita GDP") cellrange(A2:GL200)
rename A year
drop if year == ""
keep year FL-GL
gen obs = _n

*rename and reshape gdpcap columns
rename FN gdpcapAUS
rename FQ gdpcapFRN
rename FT gdpcapGMY
rename FW gdpcapITA
rename FZ gdpcapUKG
rename GC gdpcapUSA
rename GF gdpcapRUS
rename GI gdpcapCHN
rename GL gdpcapJPN

*rename  gdp columns
rename FL gdpAUS
rename FO gdpFRN
rename FR gdpGMY
rename FU gdpITA
rename FX gdpUKG
rename GA gdpUSA
rename GD gdpRUS
rename GG gdpCHN
rename GJ gdpJPN

*rename pop columns
rename FM popAUS
rename FP popFRN
rename FS popGMY
rename FV popITA
rename FY popUKG
rename GB popUSA
rename GE popRUS
rename GH popCHN
rename GK popJPN

*reshape
reshape long gdp gdpcap pop, i(obs) j ("stateabb", string)
drop if obs==1
drop obs
destring year gdpcap gdp pop, replace

*create COW ccodes
kountry stateabb, from(cowc) to(cown)
replace _COWN_=300 if _==305
rename _COWN_ ccode
save RetrenchCore, replace

*Format EUGENE data using EUGENE output file
do "./data/do files/eugeneretrenchDO"
rename cap cinc
drop if ccode==260 & year == 1990
replace ccode=255 if ccode==260
save "./data/temp/eugene.dta", replace

*format Jo and Gartzke nuclear status data
use "./data/raw data/jo_gartzke_0207_replicate_0906.dta", clear
rename ccode1 ccode
rename nuke_df nukposs
label variable nukposs "possess nuclear weapons == 1"
keep ccode year nukposs
save "./data/temp/jogartzke", replace

*format MID DV data
do "./data/do files/retrenchdv.do"
clear

*create ongoing MID control variable
do "./data/do files/weighted.do"
replace countall=0 if countall==.
replace l_count = 0 if l_count==.
replace l_wtct = 0 if l_wtct==.

clear

*Merge Data Together
use RetrenchCore.dta, clear
*merge in eugene data
merge 1:1 ccode year using "./data/temp/eugene.dta"
drop _merge

merge 1:1 ccode year using "./data/temp/jogartzke.dta"
replace nukposs=0 if nukposs==.
drop _merge

merge 1:1 ccode year using "./data/temp/weighted.dta"
replace weightedcount=0 if weightedcount==.
drop fatality hostlev
drop _merge

*merge in MID DV data
merge 1:1 ccode year using "./data/temp/retrenchdv.dta"
replace midfatdummy=0 if midfatdummy==.
replace middummy=0 if middummy==.
replace midct=0 if midct==.
replace midfatct=0 if midfatct==.
drop _merge

***Clean Up Data
*Drop unnecessary countries
keep if inlist(ccode, 002, 200, 220, 255, 300, 325, 365, 710, 740)

*Drop unnecessary years
drop if year<1869 
drop if year>2007 

*Drop USA, CHN, JPN, and ITA before they gain major power status
drop if ccode==325 & year<1860
drop if ccode==710 & year<1950
drop if ccode==002 & year<1898
drop if ccode==740 & year<1895

*Drop AUH and ITA after they lose major power status
drop if ccode==300 & year>1918
drop if ccode==325 & year>1943

***Imputation
mi set flong
mi register imputed milper milex energy irst upop tpop s_lead imports polity2 gdp gdpcap
mi register imputed cinc
mi impute mvn s_lead imports, add(5) rseed(1473116) by(ccode)
mi impute mvn cinc milper milex energy irst tpop upop, replace rseed(1473116) by(ccode)
mi impute mvn gdp gdpcap, replace rseed(1473116) by(ccode)

*Average each of the imputations
bys ccode year: egen meanv=mean(milex)
bys ccode year: replace milex = meanv if milex==.
drop meanv
bys ccode year: egen meanv=mean(s_lead)
bys ccode year: replace s_lead = meanv if s_lead==.
drop meanv
bys ccode year: egen meanv=mean(imports)
bys ccode year: replace imports = meanv if imports==.
drop meanv
bys ccode year: egen meanv=mean(exports)
bys ccode year: replace exports = meanv if exports==.
drop meanv
bys ccode year: egen meanv=mean(gdpcap)
bys ccode year: replace gdpcap = meanv if gdpcap==.
drop meanv

*Cleanup
mi unset
drop if mi_m>0
drop mi_*
xtset ccode year

***Variable Creation
sort ccode year

*Create logged and differenced GDP per capita
gen loggdpcap = log(gdpcap)
bys ccode: gen loggdpcapdiff = D.loggdpcap
gen logmilex = log(milex)
bys ccode: gen logmilexdiff = D.logmilex

*create lagged versions of variables
gen L_logmilex = L.logmilex
gen L_logmilexdiff = L.logmilexdiff
gen L_loggdpcapdiff = L.loggdpcapdiff
gen L_loggdpcap = L.loggdpcap
gen L_s_lead = L.s_lead
gen L_weightedcount = L.weightedcount
gen L_nukposs=L.nukposs
gen L_polity2 = L.polity2

*create midfatdummy peaceyears
tsspell midfatdummy, fcond(l.midfatdummy==1)
rename _seq fatpeaceyr
drop _end _spell
gen fatpeaceyr2 = fatpeaceyr*fatpeaceyr
gen fatpeaceyr3 = fatpeaceyr*fatpeaceyr2

*create middummy peaceyears
tsspell middummy, fcond(l.middummy==1)
rename _seq allpeaceyr
drop _end _spell
gen allpeaceyr2 = allpeaceyr*allpeaceyr
gen allpeaceyr3 = allpeaceyr*allpeaceyr2

*create ordinal ranking
bys year: egen gdpcaptotal = total(gdpcap)
bys year: gen gdpcapratio = gdpcap/gdpcaptotal
bys year: egen gdpcaprank=rank(-gdpcapratio)
sort ccode year
gen gdpcapchange = -D.gdpcaprank

*gen percent change milex
gen logmilperc = (logmilexdiff/l.logmilex)*100
gen l_logmilperc = l.logmilperc

*percent change gdp
gen loggdpper = (d.loggdpcap/l.loggdpcap)*100
gen gdpper = (d.gdpcap/l.gdpcap)*100
gen l_gdpper = l.gdpper

*polity squared
gen polity2sq = polity2*polity2
gen l_polity2sq = l.polity2sq

*rename old variables
rename L_loggdpcap l_loggdpcap
rename L_s_lead l_s_lead

***Label vars
la var l_logmilperc "Military Expenditures (Percent Change)" 
la var l_loggdpcap "GDP/Capita"
la var nukposs "Nuclear Weapons State"
la var s_lead "Alliance Strength"
la var polity2 "Polity Score"
la var polity2sq "Polity Score Squared"
la var fatpeaceyr "Peace Years"
la var fatpeaceyr2 "Peace Years Squared"
la var fatpeaceyr3 "Peace Years Cubed"
la var l_gdpper "GDP/Capita (Percent Change)"

save RetrenchCore, replace

***Generate one year recovery variable
gen gdpcapnotabdrop = 1 if gdpcapchange+l.gdpcapchange < 0
gen gdpcapearlyrec = -1 if (F1.gdpcaprank<gdpcaprank)
gen gdpcapbegdec = 1 if gdpcapchange<0 & gdpcapearlyrec!=-1 & gdpcapnotabdrop==1
replace gdpcapbegdec=0 if gdpcapbegdec==.
gen gdpcaprec = 1 if gdpcapchange > 0 & F.gdpcapchange >=0
replace gdpcaprec = 0 if gdpcaprec ==.
la var gdpcaprec "Recovery"
gen gdpcapx =.
replace gdpcapx = 1 if gdpcapbegdec==1
replace gdpcapx = 0 if gdpcaprec==1
replace gdpcapx = 1 if l.gdpcapx==1 & gdpcapx!=0
order gdpcapx, after(gdpcaprec)
replace gdpcapx = . if gdpcapx==0 & l.gdpcapx!=1
replace gdpcapx = 1 if gdpcapx==0
replace gdpcapx = 0 if gdpcapx==.
sort ccode year
gen gdpcapcen = 1 if (f.year==.)& gdpcapx==1 & gdpcaprec != 1
order gdpcapcen, after(gdpcapx)
gen gdpcapstart = 1 if gdpcapx == 1 & l.gdpcapx!=1
tsspell gdpcapx, cond(gdpcapx==1 & l.gdpcapx==1)
drop _end _spell
rename _seq gdpcapdurct
gen gdpcapdurct2 = gdpcapdurct*gdpcapdurct
gen gdpcapdurct3 = gdpcapdurct*gdpcapdurct2
gen l_gdpcapx = l.gdpcapx
keep ccode year gdpcaprec midfatdummy gdpcapx l_gdpcapx logmilperc l_logmilperc loggdpcap l_loggdpcap gdpper l_gdpper s_lead l_s_lead nukposs polity2 polity2sq gdpcapdurct* allpeaceyr* fatpeaceyr*

*labels
la var l_gdpcapx "Relative Decline"
la var gdpcapdurct "Years in Decline"
la var gdpcapdurct2 "Years in Decline Squared"
la var gdpcapdurct3 "Years in Decline Cubed"
save Retrench1yr, replace

***Generate five year recovery variable
use RetrenchCore,clear
gen gdpcapnotabdrop = 1 if gdpcapchange+l.gdpcapchange < 0
gen gdpcapearlyrec = -1 if (F1.gdpcaprank<gdpcaprank) 
gen gdpcapbegdec = 1 if gdpcapchange<0 & gdpcapearlyrec!=-1 & gdpcapnotabdrop==1
replace gdpcapbegdec=0 if gdpcapbegdec==.
gen gdpcaprec = 1 if gdpcapchange > 0 & (F.gdpcapchange >=0) &(F2.gdpcaprank <= gdpcaprank) & (F3.gdpcaprank<gdpcaprank) & (F4.gdpcaprank<gdpcaprank)
replace gdpcaprec = 0 if gdpcaprec == .
la var gdpcaprec "Recovery"
gen gdpcapx =.
replace gdpcapx = 1 if gdpcapbegdec==1
replace gdpcapx = 0 if gdpcaprec==1
replace gdpcapx = 1 if l.gdpcapx==1 & gdpcapx!=0
order gdpcapx, after(gdpcaprec)
replace gdpcapx = . if gdpcapx==0 & l.gdpcapx!=1
replace gdpcapx = 1 if gdpcapx==0
replace gdpcapx = 0 if gdpcapx==.
sort ccode year
gen gdpcapcen = 1 if (f.year==.)& gdpcapx==1 & gdpcaprec != 1
order gdpcapcen, after(gdpcapx)
gen gdpcapstart = 1 if gdpcapx == 1 & l.gdpcapx!=1
tsspell gdpcapx, cond(gdpcapx==1 & l.gdpcapx==1)
drop _end _spell
rename _seq gdpcapdurct
gen gdpcapdurct2 = gdpcapdurct*gdpcapdurct
gen gdpcapdurct3 = gdpcapdurct*gdpcapdurct2
gen l_gdpcapx = l.gdpcapx
keep ccode year gdpcaprec midfatdummy gdpcapx l_gdpcapx logmilperc l_logmilperc loggdpcap l_loggdpcap gdpper l_gdpper s_lead l_s_lead nukposs polity2 polity2sq gdpcapdurct* allpeaceyr* fatpeaceyr*

*labels
la var l_gdpcapx "Relative Decline"
la var gdpcapdurct "Years in Decline"
la var gdpcapdurct2 "Years in Decline Squared"
la var gdpcapdurct3 "Years in Decline Cubed"
save Retrench5yr, replace

