#!/bin/bash

# arguements:
#  1) decoded ping360 log files
#  2) All datatypes desired
#     Supported options:
#       mode
#       gain_setting
#       angle
#       transmit_duration
#       sample_period
#       transmit_frequency
#       number_of_samples
#       data_length
#       data
#       timestamp

# name output directory based on input log filename
directory=${1%%.*}

# save datatype arguements to an array
i=0
for var in ${@:2}; do
  DATATYPES[$i]=$var
  i=$((i+1))
done

# make array of output filenames
mkdir -p $directory
for i in ${!DATATYPES[@]}; do
  OUTPUTFILES[$i]="$directory/${DATATYPES[$i]}.dat"
done

# create seperate files for each datatype and modify format:
#   1) remove line labels
#   2) remove all square brackets
#   3) replace all commas with spaces
#   4) remove all apostrophes
for i in ${!DATATYPES[@]}; do
  # grep -a "${DATATYPES[$i]}:" "$1" | sed 's/^.*: //' | sed 's/[][]//g' | sed 's/,/ /g' | sed "s/'//g" > "${OUTPUTFILES[$i]}"
  grep -a "${DATATYPES[$i]}:" "$1" | sed "s/^.*: //;s/[][]//g;s/,/ /g;s/'//g" > "${OUTPUTFILES[$i]}"
done

# timestamp is in an especially annoying format -- make this legible for matlab
# output format: h h m m s s g g g
if [[ " ${DATATYPES[*]} " =~ "timestamp" ]]; then
  # substitutions:
  #  1) remove null value + accompanying special chars : and .
  #  2) change "\x" to " 0x" at start of each hex value
  #  3) remove leading space from each line
  sed -i.bak 's/\\x00://g;s/\\x00\.//g;s/\\x/ 0x/g;s/^.//' "$directory/timestamp.dat"
fi

# pad each row < max_num_samples with zeros for efficient loading into matlab
# I'm actually not sure if this number is ever not 1200
if [[ " ${DATATYPES[*]} " =~ "data" ]]; then
  nmaxcol=$(awk '{if (NF > max) max = NF} END{print max}' "$directory/data.dat" )
  nmincol=$(awk 'BEGIN{min=1200} {if (NF < min) min = NF} END{print min}' "$directory/data.dat" )
  if (( $nmincol < $nmaxcol )); then
     echo "inconsistent number of samples between messages. Tread carefully."
     # adds empty fields to any short row
     awk -v n=$nmaxcol '{$n=$n}1' "$directory/data.dat" > "$directory/data.bak"
     # fills empty fields with 0s
     sed 's/  / 0 0/g' "$directory/data.bak" > "$directory/data.dat"
  fi
fi

# delete any backup files
if file -f "$directory/*.bak"; then
  rm $directory/*.bak
fi
