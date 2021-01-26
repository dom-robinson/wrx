#New SDR? First run this and leave it for 10 mins. 
#Note the average PPM once the cumulative PPM has settled and is not varying much.

#rtl_test -p

#Also note that the ppm and gain are set in two places. 
#First in receive_and_process_satellite.sh
#Look for the rtl-fm line and change the -g for gain and -p for PPM

#then in rtlsdr_m2_lrpt_rx.py
#change the ppm ('3') here: self.rtlsdr_source_0.set_freq_corr(3, 0) 
#and the gain ('43.9') here: self.rtlsdr_source_0.set_gain(43.9, 0)

#remember crontab schedules all the tasks into 'at'


#Add a pi crontab - adjust the +2 to maintain .s and wav IQ capture files for more than 2 days. 
#Similarly +60 adjustments for removing old files (60 days default).

1 0 * * * /home/pi/weather/predict/schedule_all.sh
0 0 * * * find /home/pi/weather/tests/* -mtime +2 -type f -delete
0 0 * * * find /home/pi/weather/archives/* -mtime +60 -type f -delete


#to remove at job 176 use 
#atrm 176

#I used lighttpd as a basic webserver with its root at /home/pi/weather

#To enable mail sending follow this: https://doc.ubuntu-fr.org/msmtp

sudo apt install msmtp msmtp-mta

sudo nano ~/.msmtprc

#----

#Set default values for all following accounts.
defaults
auth           on
tls            on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
logfile        ~/.msmtp.log

#Gmail
account        gmail
host           smtp.gmail.com
port           587
from           satellitewrx@gmail.com
user           satellitewrx@gmail.com
password       xfVi3DLfVil4


#Set a default account
account default : gmail

#-----

chown pi:pi .msmtprc 
chmod 400 .msmtprc


----

#then use

mpack -s ${3}-$i ${NOAA_OUTPUT}/images/${3}-$i.jpg wrx.XXXX@zapiermail.com

#to feed to facebook.


---

