#!/bin/bash
echo `dirname $0`
cd `dirname $0`
#/Applications/Octave.app/Contents/Resources/bin/octave --silent < ./make_tools_help_list.m
octave --silent --path ../../mataa_tools ./make_tools_help_list.m
#makeinfo --html --no-split MATAA_manual.texi
#rm ../MATAA_manual.html
#mv MATAA_manual.html ..
#open ../MATAA_manual.html
texi2pdf MATAA_manual.texi
rm ../MATAA_manual.pdf
mv MATAA_manual.pdf ..
open ../MATAA_manual.pdf
