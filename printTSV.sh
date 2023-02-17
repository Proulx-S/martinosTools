#!/bin/bash
niiDir=$1
filt=$2

tmp=$(mktemp)
paste <(echo -e fileId\\n------) \
      <(echo -e TR\\n--) \
      <(echo -e TE\\n--) \
      <(echo -e FA\\n--) \
      <(echo -e PixelSpacing\\n------------) \
      <(echo -e slc\\n---) \
      <(echo -e thick\\n-----) \
      <(echo -e space\\n-----) \
      <(echo -e seqName\\n-------) \
      <(echo -e serDesc\\n-------) \
      > $tmp
paste <(basename -a $niiDir/*.json | awk -F___ '{print $1}') \
      <(jq '.RepetitionTime' $niiDir/*.json) \
      <(jq '.EchoTime' $niiDir/*.json) \
      <(jq '.FlipAngle' $niiDir/*.json) \
      <(jq '.PixelSpacing' $niiDir/*.json) \
      <(jq '.NumberOfSlices' $niiDir/*.json) \
      <(jq '.SliceThickness' $niiDir/*.json) \
      <(jq '.SpacingBetweenSlices' $niiDir/*.json) \
      <(jq '.SequenceName' $niiDir/*.json) \
      <(jq '.SeriesDescription' $niiDir/*.json) \
      >> $tmp

if [ -z "$filt" ]; then
    column -ts $'\t' $tmp
    rm $tmp
else
    tmp2=$(mktemp)
    head -2 $tmp > $tmp2
    grep $filt $tmp >> $tmp2
    column -ts $'\t' $tmp2
    rm $tmp $tmp2
fi

