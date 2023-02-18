#!/bin/bash
###########################################
##############    PLUMBING   ##############
## Error tracking
set -eE -o functrace
set +o noclobber
failure() {
    local lineno=$1
    local msg=$2
    echo "Failed at $lineno: $msg"
}
trap 'failure ${LINENO} "$BASH_COMMAND"' ERR
###########################################
###########################################


###########################################
##############   Automatic   ##############
main() {
    projDir=$1
    SUBJECT=$2
    DATE=$3
    BAY=$4
    sub=$5
    ses=$6
    skipPromptFlag=$7

    ## Store findsession output and set some dir
    # rm -f $projDir/code/sub-${sub}_ses-${ses}.info
    findsession -o $DATE -f $BAY $SUBJECT | tail -7 > $projDir/sub-${sub}_ses-${ses}.info

    ## Set some directories
    dcmDir_source=$(cat $projDir/sub-${sub}_ses-${ses}.info | grep PATH | awk -F: '{print $2}' | awk '{$1=$1};1')
    dcmDir=$projDir/sub-$sub/ses-$ses/mri/dcm; mkdir -p $dcmDir
    niiDir=$projDir/sub-$sub/ses-$ses/mri/nii;

    ## Confirm everything is ok
    if [ ! $skipPromptFlag ]; then
	printf '%s\n'; printf '\U2193%.0s' {1..7}; printf '%s\n'; \
	    echo =======; echo  bids name: sub-${sub}_ses-$ses; echo $projDir; \
	    echo =======; echo dcm source: $dcmDir_source; stat -c "User:%U Group:%G" $dcmDir_source; echo "$(ls $dcmDir_source | wc -l) files"; \
	    echo =======; echo findsession output:; \
	    cat $projDir/sub-${sub}_ses-${ses}.info; \
	    echo =======; \
	    if [ -f $dcmDir/../dcmunpack.index ]; then echo dcmunpack.index exists, will use it; fi; \
	    printf '\U2191%.0s' {1..7}; printf '%s\n'
	    while true; do
		read -p "Does the above looks good? (y or n)" yn
		case $yn in
		    [Yy]* ) break;;
		    [Nn]* ) rm $projDir/code/sub-${sub}_ses-${ses}.info; exit;;
		    * ) echo "Please answer yes (y or Y) or no (n or N).";;
		esac
	    done
    fi

    ## With dcmunpack, copy original dcm and extract metadata (in $dcmDir/log/*-infodump.dat)
    rm -f $dcmDir/../dcmunpack.log $dcmDir/../*.dat
    rm -r $dcmDir; mkdir -p $dcmDir
    if [ -f $dcmDir/../dcmunpack.index ]; then
	dcmunpack -copy-only -generic -no-exit-on-error \
		  -auto-runseq nii.gz \
		  -src $dcmDir_source \
		  -targ $dcmDir \
		  -index-in $dcmDir/../dcmunpack.index \
		  -log $dcmDir/../dcmunpack.log
    else
	dcmunpack -copy-only -generic -no-exit-on-error \
		  -auto-runseq nii.gz \
		  -src $dcmDir_source \
		  -targ $dcmDir \
		  -index-out $dcmDir/../dcmunpack.index \
		  -log $dcmDir/../dcmunpack.log
    fi
    mv -f $dcmDir/*.dat $dcmDir/..

    ## With dcm2nii, convert to nii
    rm -rf $niiDir; mkdir -p $niiDir
    /usr/pubsw/bin/dcm2niix -z y -ba n -f serNo-%s_instNo-%r -o $niiDir $dcmDir

    ## Set pheonix report asside
    if [ `grep -l "Phoenix Document" $niiDir/*.json` ]; then
	phnx=$(grep -l "Phoenix Document" $niiDir/*.json)
	phnx=$(basename $phnx .json)
	mkdir -p $niiDir/phoenixDoc
	mv $niiDir/$phnx.json $niiDir/phoenixDoc/$phnx.json
	mv $niiDir/$phnx.nii.gz $niiDir/phoenixDoc/$phnx.nii.gz
    fi

    ## Rename nii to something that makes more sense
    ### Painfully generate RunNumber, a unique number for each scanner run. This relies on SeriesNumber and AcquisitionTime: two files from the same acquisition run can have different series number but the same acquisition time (e.g. phase and magnitude images), and two files with the same series number (instances) can have different acquisition times (e.g. multiecho data). !!!BEWARE!!! the RunNumber generate here will not necesserily match the run number in the task list on Siemens' console.------UPDATE: Actually, some multi-echo sequences (see findsession -I 18.10.31-15:38:03-DST-1.3.12.2.1107.5.2.43.67026) seems to produce files with different SeriesNumber for different echos. So the code below will give the same RunNumber to those :-( Correcting this will be hard...
    tmpDir=$(mktemp -d)
    # rm -f $tmpDir/sub-${sub}_ses-${ses}_*
    #### get SeriesNumber
    jq -r '.SeriesNumber' $niiDir/*.json > $tmpDir/seriesNumberX
    printf %03d\\n `cat $tmpDir/seriesNumberX` > $tmpDir/seriesNumber
    rm $tmpDir/seriesNumberX
    #### get AcquisitionTime
    jq -r '.AcquisitionTime' $niiDir/*.json > $tmpDir/acquisitionTimeX
    date -f $tmpDir/acquisitionTimeX +%H:%M:%S.%N > $tmpDir/acquisitionTime
    rm $tmpDir/acquisitionTimeX
    #### get fileName
    basename -a -s .json `ls $niiDir/*.json` > $tmpDir/fileName
    #### put in a single table and sort it
    rm -f $tmpDir/longList
    paste $tmpDir/acquisitionTime $tmpDir/seriesNumber $tmpDir/fileName > $tmpDir/longList
    rm -f $tmpDir/longListX
    sort -k 1 $tmpDir/longList > $tmpDir/longListX
    mv -f $tmpDir/longListX $tmpDir/longList
    #### get lowest SeriesNumber of each instances with the same AcquisitionTime
    uTimes=(`awk '{print $1}' $tmpDir/longList | sort | uniq`)
    unset uSeries
    for uTime in ${uTimes[@]}; do
	uSeries+=(`awk -v uTime=$uTime ' $1 == uTime {print $2} ' $tmpDir/longList | sort | head -1`)
    done
    rm -f $tmpDir/uTimes
    printf '%s\n' "${uTimes[@]}" > $tmpDir/uTimes
    rm -f $tmpDir/uSeries
    printf '%s\n' "${uSeries[@]}" > $tmpDir/uSeries
    rm -f $tmpDir/u
    paste $tmpDir/uTimes $tmpDir/uSeries > $tmpDir/u
    #### add it to the single table
    rm -f $tmpDir/uX
    while read line; do
	v=$(echo $line | awk '{print $1}')
	awk -v v=$v ' $1 == v {print $2}' $tmpDir/u >> $tmpDir/uX
    done < $tmpDir/longList
    paste $tmpDir/longList $tmpDir/uX > $tmpDir/longListX
    mv -f $tmpDir/longListX $tmpDir/longList
    rm -f $tmpDir/uX $tmpDir/u $tmpDir/uSeries $tmpDir/uTimes
    #### define RunNumber
    uuSeries=(`printf '%s\n' "${uSeries[@]}" | sort | uniq`)
    uuRuns=(`seq -f %03g 1 1 ${#uuSeries[@]}`)
    rm -f $tmpDir/uuSeries
    printf '%s\n' "${uuSeries[@]}" > $tmpDir/uuSeries
    rm -f $tmpDir/uuRuns
    printf '%s\n' "${uuRuns[@]}" > $tmpDir/uuRuns
    rm -f $tmpDir/uu
    paste $tmpDir/uuSeries $tmpDir/uuRuns > $tmpDir/uu
    rm -f $tmpDir/uuSeries $tmpDir/uuRuns
    #### add it to the single table, keeping only fileName
    rm -f $tmpDir/uuX
    while read line; do
	v=$(echo $line | awk '{print $4}')
	awk -v v=$v ' $1 == v {print $2}' $tmpDir/uu >> $tmpDir/uuX
    done < $tmpDir/longList
    rm -f $tmpDir/longListX
    awk '{print $3}' $tmpDir/longList > $tmpDir/longListX
    mv -f $tmpDir/longListX $tmpDir/longList
    paste $tmpDir/uuX $tmpDir/longList > $tmpDir/longListX
    mv -f $tmpDir/longListX $tmpDir/longList
    rm -f $tmpDir/uu $tmpDir/uuX

    #### Do the renaming
    for jsn in $niiDir/*.json; do
	fileName=`basename $jsn .json`
	nii=`dirname $jsn`/$fileName.nii.gz
	### runNumber
	runNo=`awk -v f=$fileName ' $2 == f {print $1}' $tmpDir/longList`
	### seriesNumber
	serNo=$(printf %03d `jq -r '.SeriesNumber' $jsn`)
	### instanceNumber
	instNo=$(printf %02d `echo $fileName | awk -F_ '{print $(2)}' | awk -F- '{print $(2)}'`)
	### seriesDescription
	serDesc=`jq -r '.SeriesDescription' $jsn`
	serDesc="${serDesc// /_}"
	### rename
	fileName=r${runNo}s${serNo}i${instNo}___$serDesc
	mv $jsn $niiDir/$fileName.json
	mv $nii $niiDir/$fileName.nii.gz
	### add some more info
	dat=$(readlink -f $dcmDir/../0$serNo.*.dat)
	projDir_tmp=$(readlink -f $projDir)/
	niiDir_tmp=$(readlink -f $niiDir)
	tmp=$(mktemp)
	#### conversion software
	jq '. |= .+ {"ConversionSoftware": ["dcmunpack","'`jq -r '.ConversionSoftware' $niiDir/$fileName.json`'"]}' $niiDir/$fileName.json > "$tmp" && mv -f "$tmp" $niiDir/$fileName.json
	dcmunpackV=$(dcmunpack -version | awk '{print$2}')
	jq '. |= .+ {"ConversionSoftwareVersion": ["'$dcmunpackV'","'`jq -r '.ConversionSoftwareVersion' $niiDir/$fileName.json`'"]}' $niiDir/$fileName.json > "$tmp" && mv -f "$tmp" $niiDir/$fileName.json
	jq '. |= .+ {"Sources": ["bids:'$(basename $projDir)':'${dat#$projDir_tmp}'","bids:'$(basename $projDir)':'${niiDir_tmp#$projDir_tmp}'"]}' $niiDir/$fileName.json > "$tmp" && mv -f "$tmp" $niiDir/$fileName.json
	#### geometry
	pixSpace=$(grep -h PixelSpacing $dat | awk '{print $2}' | tr -d ' ')
	nSlc=$(grep -h sSliceArray.lSize $dat | awk -F= '{print $2}' | tr -d ' ')
	jq '. |= .+ {"PixelSpacing": "'${pixSpace/\\//}'"}' $niiDir/$fileName.json > "$tmp" && mv -f "$tmp" $niiDir/$fileName.json
	jq '. |= .+ {"NumberOfSlices": "'`echo $nSlc`'"}' $niiDir/$fileName.json > "$tmp" && mv -f "$tmp" $niiDir/$fileName.json
    done
    rm -r $tmpDir
}
###########################################
###########################################

main $1 $2 $3 $4 $5 $6 $7

