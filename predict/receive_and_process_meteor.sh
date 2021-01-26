#! /bin/bash
# $1 = Satellite Name
# $2 = Frequency
# $3 = FileName base
# $4 = TLE File
# $5 = EPOC start time
# $6 = Time to capture

echo "Acquiring " ${3}

#grab the feed from the SDR
cd /home/pi/weather
timeout $6 predict/rtlsdr_m2_lrpt_rx.py $1 $2 $3

NOW=$(date +%m-%d-%Y)
mkdir -p /home/pi/weather/archives/${NOW}


#at some point we will need auto detect for summer / winter here
# Winter
medet/medet_arm ${3}.s $3 -r 68 -g 65 -b 64 -na -s

# Summer
#medet/medet_arm ${3}.s $3 -r 66 -g 65 -b 64 -na -s

if [ -f "${3}_0.bmp" ]; then
        dte=`date +%H`

        # Winter
        convert ${3}_1.bmp ${3}_1.bmp ${3}_0.bmp -combine -set colorspace sRGB ${3}.bmp
        convert ${3}_2.bmp ${3}_2.bmp ${3}_2.bmp -combine -set colorspace sRGB -negate ${3}_ir.bmp

        # Summer
        #convert ${3}_0.bmp ${3}_1.bmp ${3}_2.bmp -combine -set colorspace sRGB ${3}.bmp

        meteor_rectify/rectify.py ${3}.bmp
        meteor_rectify/rectify.py ${3}_ir.bmp

        if [ $dte -lt 13 ]; then
                convert ${3}-rectified.png -normalize -quality 90 $3.jpg
                convert ${3}_ir-rectified.png -normalize -quality 90 ${3}_ir.jpg
        else
                convert ${3}-rectified.png -rotate 180 -normalize -quality 90 $3.jpg
                convert ${3}_ir-rectified.png -rotate 180 -normalize -quality 90 ${3}_ir.jpg
        fi



        #only update if images is good - evaluate from logic that rect is usually larger than bmp when good.
        recfilesize=$(wc -c < ${3}-rectified.png)
        compfilesize=$(wc -c < ${3}_0.bmp)

        if [ $recfilesize -ge $compfilesize ]; then

                #update the webpage latest
                cp ${3}.jpg ./latest/latestmeteor-nolabel.jpg
                composite label:${3} ./latest/latestmeteor-nolabel.jpg ./latest/latestmeteor.jpg
                mpack -s ${3} ./latest/latestmeteor.jpg wrx.o0gnwd@zapiermail.com
                rm ./latest/latestmeteor-nolabel.jpg

                echo "Processed"

        else
                echo "Bad Image"
        fi


#tidy up
#        rm $3.bmp
#        rm ${3}_0.bmp
#        rm ${3}_1.bmp
#        rm ${3}_2.bmp
#        rm ${3}-rectified.png

        # Winter only
#        rm ${3}_ir.bmp
#        rm ${3}_ir-rectified.png

fi


#dom: lets not remove this for moment
mv ${3}.s ./tests/

# moves all output files to the archive folder
mv ${3}* ./archives/${NOW}/
