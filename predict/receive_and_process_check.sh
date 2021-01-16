#!/bin/bash

NOW=$(date +%m-%d-%Y)
TIMER=600
mkdir -p /home/pi/weather/tests/

#create a sample test.s file filling in data with METEORTEST dummy to trigger output of .s
#timeout 60 predict/rtlsdr_m2_lrpt_rx.py METEORTEST 137.1 /home/pi/weather/tests/METEORTEST METEORTEST METEORTEST METEORTEST

#Check that a .s file will get processed. Wont produce output since will only contain noise. However will show the decode process working.
#/home/pi/weather/predict/receive_and_process_meteor.sh METEORTEST 137.1 /home/pi/weather/tests/METEORTEST /home/pi/weather/predict/weather.tle $NOW $TIMER


#Takes a 10 second wav file from sdr and pushes it through wxtoimg. No correct timing data yet so currently barfs at producing the map, but otherwise works.
/home/pi/weather/predict/receive_and_process_satellite.sh NOAATEST 137.1 /home/pi/weather/tests/NOAATEST /home/pi/weather/predict/weather.tle $NOW $TIMER 


