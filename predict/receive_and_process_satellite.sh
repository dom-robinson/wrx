#!/bin/bash
# $1 = Satellite Name
# $2 = Frequency
# $3 = FileName base
# $4 = TLE File
# $5 = EPOC start time
# $6 = Time to capture


echo "Acquiring " ${3}

# reads and creates folder with current date / time (i.e 05-30-2019_07-48 *windows friendly*)
# dom: removed time. Want to group each day not pass.
NOW=$(date +%m-%d-%Y)
mkdir -p /home/pi/weather/archives/${NOW}

cd /home/pi/weather

#dom: this is the secrect sauce to tune the SDR and LNA etc.
sudo timeout $6 rtl_fm -f ${2}M -g 43.9 -p 3 -s 48k -E deemp -F 9 - | sox -t raw -e signed -c 1 -b 16 -r 48000 - $3.wav rate 11025


#dom: image processing
PassStart=`expr $5 + 90`

if [ -e $3.wav ]
 then
	/usr/local/bin/wxmap -T "${1}" -H $4 -p 0 -l 0 -o $PassStart ${3}-map.png
	/usr/local/bin/wxtoimg -m ${3}-map.png -e ZA $3.wav ${3}.png
	/usr/local/bin/wxtoimg -m ${3}-map.png -e NO $3.wav ${3}.NO.png
	/usr/local/bin/wxtoimg -m ${3}-map.png -e MCIR $3.wav ${3}.MCIR.png
	/usr/local/bin/wxtoimg -m ${3}-map.png -e MSA $3.wav ${3}.MSA.png

	label=${3##*/}
	#update webpage latest and label it.
	cp ${3}.MCIR.png ./latest/latestnoaa-nolabel.png
	composite label:$label ./latest/latestnoaa-nolabel.png ./latest/latestnoaa.png
	mpack -s $label ./latest/latestnoaa.png wrx.o0gnwd@zapiermail.com
	rm ./latest/latestnoaa-nolabel.png

	#remove map now it is blended.
	rm ${3}-map.png
fi



# moves output files to the archive
mv ${3}.wav /home/pi/weather/tests/
mv ${3}* /home/pi/weather/archives/${NOW}/

