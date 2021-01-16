#New SDR? First run this and leave it for 10 mins. 
#Note the average PPM once the cumulative PPM has settled and is not varying much.

#rtl_test -p

#Also note that the ppm and gain are set in two places. 
#First in receive_and_process_satellite.sh
#Look for the rtl-fm line and change the -g for gain and -p for PPM
#
#then in rtlsdr_m2_lrpt_rx.py
#change the ppm ('3') here: self.rtlsdr_source_0.set_freq_corr(3, 0) 
#and the gain ('43.9') here: self.rtlsdr_source_0.set_gain(43.9, 0)
#
#remember crontab schedules all the tasks into 'at'
# to remove at job 176 use 
# atrm 176
#
# use https://doc.ubuntu-fr.org/msmtp for this release of raspbian
