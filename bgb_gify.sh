# this script records 4 second gameplay of each of the examples and creates a
# gif at /tmp/gameboy/clip.gif
# note that under APPLY CORRECTIONS I have some custom offsets for recording
# that account for window decorations
# if using i3 you'll need to skip these


## ========== STEP 0: Compile game (recursively run itself if no game provided)
if [[ $# == 0 ]]; then
    mkdir /tmp/gameboy
    mkdir /tmp/gameboy/gifs
    for filename in [0-9]**.asm; do
        $0 $filename $PWD/$filename
    done
    # exit so that this process does not continue running
    exit 0
fi

## ======== STEP 0.5 compile $1 game
echo "assembling...$2"
rgbasm -o $2.obj $2
echo linking objects and dependencies
rgblink -o a.gb $2.obj
echo fixing...
# -v verbose. -p0 for padding value. Aka pad with 0's up to 32KB increments
rgbfix -v -p0 a.gb
rm $2.obj


## =========== STEP 1: PLAY GAME
echo emulating game
bgbDIR="$HOME/bin/bgb"
# run bgb from wine with newly created ROM. Redirect (&>) both stdout and
# stderr into winelog.txt for silent mode
wine "$bgbDIR/bgb.exe" a.gb &> $bgbDIR/winelog.txt &
bgbPID=$!   # get PID of bgb
echo "bgbPID = $bgbPID"

## =========== STEP 2: RECORD GAMEPLAY

## ======== STEP 2.3: WAIT FOR BGB WINDOW TO POP UP
# wait until bgb window pops up
# you'll probably need to INSTALL XDOTOOL
while [ $(xdotool getactivewindow getwindowpid) -ne $bgbPID ]; do
    sleep 0.001
done
echo getting active window position and sizing
## ======== STEP 2.6: GET BGB WINDOW'S POSITION AND SIZE
xdotool getactivewindow getwindowpid getwindowgeometry
# returns the following string:
# Window 37748771
#   Position: 524,250 (screen: 0)
#   Geometry: 320x288

# using sed for string replacement (with "")
dimensions=$(xdotool getactivewindow getwindowgeometry | grep Geometry | sed -e "s/  Geometry: //")
position=$(xdotool getactivewindow getwindowgeometry | grep Position | sed -e "s/  Position: //")
position=$(echo $position | cut -f1 -d" ")

# cut -f (fragment #) -d (delimiter)
# basically -f1 -dx == take 1st fragment after string sliced by "x"
width=$(echo $dimensions | cut -f1 -dx)
height=$(echo $dimensions | cut -f2 -dx)
xoffset=$(echo $position | cut -f1 -d,)
yoffset=$(echo $position | cut -f2 -d,)

## ========= STEP 2.8: APPLY CORRECTIONS
# there are some cases where the x, y offset may be wrong. We can apply a
# mathematical correction here
let "yoffset=yoffset - 18"
let "xoffset=xoffset - 2"

echo width=$width height=$height xoffset=$xoffset yoffset=$yoffset
echo recording demo video now

record_time="0:00:04"
videofile=/tmp/gameboy/$1gb.mpg
mkdir /tmp/gameboy/
# -y == yes always overwrite files
# -t (time) H:MM:SS.DCM
# x11grab (grab input from X11 screen)
# -r 20 (input framerate of 20)
# -s (size) (aka 620x480)
# -i (input?? which screen, I suppose) :0.0+offset (:0.0 is screen I believe)
# -qscale 0 (quality -- prevent artifacts? No compression, I think)
ffmpeg -y -t $record_time -f x11grab -r 20 -s $dimensions -i :0.0+$xoffset,$yoffset -qscale 0 $videofile

# done, cool. Now kill bgb
kill $bgbPID

## =========== STEP 3: GIF-ify it

# now let's decompose that video into frames
prefix=$1gb
imageprefix=/tmp/gameboy/$prefix

rm $imageprefix*.png

# ratio and delay are interlinked. 5 frames per 1 second?
# then better make the delay 200ms
ratio=3/1
delay=30

ffmpeg -i $videofile -r $ratio $imageprefix%03d.png
rm $videofile

# now let's recombine those frames into a gif
echo ...converting into gif using convert...
clip=/tmp/gameboy/$1clip.gif

convert -loop 0 -delay $delay $imageprefix*.png $clip

## ============= STEP 3.3: GIF-ify resized images
# [optional] pngquantize it first to reduce # of colors
echo resizing images
for imagefile in $imageprefix*.png; do
    # -sample (instead of -resize) resizes but with pixel sampling
    # so it'll retain the same colors
    convert $imagefile -sample 160x144 $imagefile
done
#convert $imageprefix*.png -resize 160x144 $imageprefix*.png

clip2=/tmp/gameboy/$1clip2.gif
# now convert those resized images into a gif
echo ...gifying resized images...
convert -loop 0 -delay $delay $imageprefix*.png $clip2

# delete temporary images
rm $imageprefix*.png

## ============ STEP 3.6: Keep smaller gif
# compare filesizes. Keep smaller one
clip_kb=`du -k "$clip" | cut -f1`
clip2_kb=`du -k "$clip2" | cut -f1`
# if [ "$clip_kb" -lt "$clip2_kb" ]; then
if (( $clip_kb < $clip2_kb )); then
    echo ORIGINAL gif was smaller
    rm $clip2
else
    echo resized gif was smaller
    rm $clip
    mv $clip2 $clip
fi

mv $clip /tmp/gameboy/gifs/

# DONE!
