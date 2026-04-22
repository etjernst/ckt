
READ-ME FOR:
Average Treatment Effects for Stayers with Correlated Random Coefficient Models of Panel Data, Valentin Verdier, Journal of Applied Econometrics, forthcoming.

- - - - - - - - - - - - - - - - - - DATA PREPARATION - - - - - - - - - - - - - - - - - - - - - - - - 

1. Household Survey Data.

The household data used in this paper are available to other researchers, but access to the data requires that a data use agreement be signed by the researchers and the Tegemeo Institute at Egerton Institute.
The data policy of the institute is found here: https://www.tegemeo.org/images/downloads/data/Data-Policy.pdf A request for the data used in this paper can be submitted here: https://www.tegemeo.org/index.php/resources/data/230-request-for-data.html. In order to replicate the results in this paper, researchers should request the household survey data for years 1997, 2004, 2007, and 2010 with GPS coordinates included (the latter is needed for the rainfall data to be merged in).

2. Rainfall Data.

Once the data files above are obtained, rainfall data for each household can be merged in using the GPS coordinates for each household, GIS, and the publicly available data on daily precipitation made available by the Climate Prediction Center (CPC) of the National Weather Service. These data are available here: https://www.cpc.ncep.noaa.gov/products/GIS/GIS_DATA/. The dates for rainfall seasons across all geographical regions in Kenya are given in  "data/Rainfall Periods for Tegemeo Sample Villages (by Division).pdf" (these dates apply to every year of the data). In addition, this rainfall dataset has already been compiled by the Tegemeo Agricultural Policy Research and Analysis Project (TAPRA) and can be obtained by requesting the "General Data" files from the Tegemeo institute using the link provided above.

3. Data Processing Code

The raw data obtained from Tegemeo was placed in the folder /data/data/raw. The architecture of folders was preserved (without data files) to make replication by other researchers easier. In particular, we see that the files were divided into household surveys for years 1997, 2000, 2004, 2007, 2010, and a folder named General Data containing, in particular, the rainfall data discussed above.
From the raw file, the panel dataset used for analysis (data/panels/SuriPanel_extended.dta) is created by the do files (1) /data/src/data_prep.do and (2) data/src/panel_creation.do.

- - - - - - - - - - - - - - - - - - ANALYSIS CODE - - - - - - - - - - - - - - - - - - - - - - - - 

1. Table 1

The results in Table 1 can be replicated with the dataset SuriPanel_extended.dta created above and by running the code Table1/Code/extrapolation.do.

2. Figure 2

Run Figure2/Code/graph_extrapolations.do to replicate Figure 2.

3. Footnote 31

The test in footnote 31 (overidentification test of the CRC model) can be replicated using the code in the Footnote31 folder. Obtain the results for 10,000 bootstrap draws (20 times 500) by running the shell script Code/run.sh. Then obtain the p-value by running Code/results_bootstrap_overid_CRC.do.

4. Alternative test of the simple extrapolation

In section 4.2.3 we discuss an alternative test of the validity of the extrapolation to stayers, using average distance to the nearest seed seller instead of an over-identification test as reported in Table 1. The code to obtain these results is found in the folder "test_distance". Obtain the results for 10,000 bootstrap draws (20 times 500) by running the shell script Code/run.sh. Then obtain the p-value by running results_testdist.do.

END OF FILE


