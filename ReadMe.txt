Master Functions
==================
get_data
burst_features
get_gapes

The file “plot_emg_spike_train.m’ contains a small demo of these three master functions.
I’ve also provided a data file that you can use for the demo: ’120530jxl36.nex’

You need to change some of the path definitions in ‘get_data’ and ‘get_gapes’ depending on where you will be storing your data and your algorithm specification matrix (QDA_nostd_no_first.mat) 


Function Dependencies
===================
get_data
	readNexFile
	removing_bad_events
	keep_significant_response
	timestamps_to_spiketrain
	make_spike_arrays

burst_features
	convolve_by
	peakdet
	get_features
	remove_rows

get_gapes
	burst_features


Coefficients for Quadratic Classifier (used in get_gapes)
=====================================
QDA_nostd_no_first


@(x,y)    important_coefficients(1) 
 	+ important_coefficients(2)*x 
	+ important_coefficients(3)*y
        + important_coefficients(4)*x.^2
	+ (important_coefficients(5))*x.*y 
	+ important_coefficients(6)*y.^2

x=peak_to_peak
y=duration

