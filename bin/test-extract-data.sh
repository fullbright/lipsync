#!/bin/bash

arr=$(sed -n -e '$!N' -e 's/\n//g' -e 's/.*{\([^{][^{]*\)}.*/\1/gp' helenasync.lua)

for x in $arr
do
    echo $x
done
