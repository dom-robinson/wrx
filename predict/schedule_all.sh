#!/bin/bash

# Update Satellite Information

wget -qr https://www.celestrak.com/NORAD/elements/weather.txt -O /home/pi/weather/predict/weather.txt
grep "NOAA 15" /home/pi/weather/predict/weather.txt -A 2 > /home/pi/weather/predict/weather.tle
grep "NOAA 18" /home/pi/weather/predict/weather.txt -A 2 >> /home/pi/weather/predict/weather.tle
grep "NOAA 19" /home/pi/weather/predict/weather.txt -A 2 >> /home/pi/weather/predict/weather.tle
grep "METEOR-M 2" /home/pi/weather/predict/weather.txt -A 2 >> /home/pi/weather/predict/weather.tle



#Remove all AT jobs

for i in `atq | awk '{print $1}'`;do atrm $i;done


#Schedule Satellite Passes:

/home/pi/weather/predict/schedule_satellite.sh "NOAA 19" 137.1000
/home/pi/weather/predict/schedule_satellite.sh "NOAA 18" 137.9125
/home/pi/weather/predict/schedule_satellite.sh "NOAA 15" 137.6200
/home/pi/weather/predict/schedule_satellite.sh "METEOR-M 2" 137.1000


#lets get a scheduled out on the web server

#atq > /home/pi/weather/passes_`date +"%m-%d-%Y"`.txt
for j in $(atq | sort -k6,6 -k3,3M -k4,4 -k5,5 |cut -f 1); do atq |grep -P "^$j\t" ;at -c "$j" | tail -n 2; done > /home/pi/weather/atqupdate_`date +"%m-%d-%Y"`.txt

cp /home/pi/weather/atqupdate_`date +"%m-%d-%Y"`.txt /home/pi/weather/today.txt
mv /home/pi/weather/atqupdate* /home/pi/weather/tests/
awk '!NF{$0="<p>"}1' /home/pi/weather/today.txt > /home/pi/weather/todayh.txt 
awk '{sub(/home\/pi\/weather\/predict\/receive_and_process_satellite.sh/,"")}1' /home/pi/weather/todayh.txt > /home/pi/weather/todayo.txt
awk '{sub(/home\/pi\/weather\/predict\/receive_and_process_meteor.sh/,"")}1' /home/pi/weather/todayo.txt > /home/pi/weather/todayh.txt
awk '{sub(/home\/pi\/weather\/predict\/weather.tle/,"")}1' /home/pi/weather/todayh.txt > /home/pi/weather/todayo.txt
sed '/<br>/r /home/pi/weather/todayo.txt' /home/pi/weather/wrapper.htm > /home/pi/weather/index
sed 's/home\/pi\/weather\///g' /home/pi/weather/index > /home/pi/weather/index.html

#cleanup
rm /home/pi/weather/index
rm /home/pi/weather/todayo.txt
rm /home/pi/weather/todayh.txt

