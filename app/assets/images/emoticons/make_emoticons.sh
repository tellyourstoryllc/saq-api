#!/bin/sh
# Requires: ImageMagick

cp originals/* .
mogrify -resize 6000x64 *.png
mogrify -resize 6000x64 *.gif
