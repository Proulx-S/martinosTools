#!/bin/bash
niiDir=$1
filt=$2

## Add table header
tmp1=$(mktemp)
paste <(echo -e fileId\\n------) \
      <(echo -e nVol\\n----) \
      <(echo -e TR\\n--) \
      <(echo -e TE\\n--) \
      <(echo -e FA\\n--) \
      <(echo -e PixelSpacing\\n------------) \
      <(echo -e slc\\n---) \
      <(echo -e thick\\n-----) \
      <(echo -e space\\n-----) \
      <(echo -e seqName\\n-------) \
      <(echo -e serDesc\\n-------) \
      > $tmp1

## Extract number of frames from .nii.gz file
tmp2=$(mktemp)
tmp3=$(mktemp)
for curJson in $niiDir/*.json
do
    mri_info --o $tmp2 --nframes ${curJson%.*}.nii.gz > /dev/null
    cat $tmp2 >> $tmp3
done
rm $tmp2

## Add table content
paste <(basename -a $niiDir/*.json | awk -F___ '{print $1}') \
      <(cat $tmp3) \
      <(jq '.RepetitionTime' $niiDir/*.json) \
      <(jq '.EchoTime' $niiDir/*.json) \
      <(jq '.FlipAngle' $niiDir/*.json) \
      <(jq '.PixelSpacing | split("/") | .[]|=tonumber | .[]|=.*1000 | .[]|=round | .[]|=./1000 | join("/")' $niiDir/*.json) \
      <(jq '.NumberOfSlices' $niiDir/*.json) \
      <(jq '.SliceThickness' $niiDir/*.json) \
      <(jq '.SpacingBetweenSlices' $niiDir/*.json) \
      <(jq '.SequenceName' $niiDir/*.json) \
      <(jq '.SeriesDescription' $niiDir/*.json) \
      >> $tmp1
rm $tmp3

## Print table, filtering it if requested
if [ -z "$filt" ]; then
    column -ts $'\t' $tmp1
    mv $tmp1 $niiDir/../nii.tsv
    printf '%s\n'; printf '\U2193%.0s' {1..7}; printf '%s\n'; \
	echo "1) Open nii.tsv"
	echo libreoffice --calc $niiDir/../nii.tsv
	echo "2) Add one column to the left"
	echo "3) Insert BIDS filenames"
	echo "4) Save as nii2bids.tsv in your bids code folder"
	    printf '\U2191%.0s' {1..7}; printf '%s\n'
	
else
    tmp4=$(mktemp)
    head -2 $tmp1 > $tmp4
    grep $filt $tmp1 >> $tmp4
    column -ts $'\t' $tmp4
    rm $tmp1 $tmp4
fi

