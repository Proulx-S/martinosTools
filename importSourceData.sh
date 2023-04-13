#!/bin/bash
source /usr/local/freesurfer/fs-dev-env-autoselect
unalias cp
dbDir=/space/takoyaki/1/users/proulxs/vasomo/source/mitra2


#############################
## Template                ##
## fill between <brackets> ##
#############################
## <StudyName> -- <SubjectUniqueID> -- <OldSubjectID>
studyId=<> #Name of the study for which data is acquired
subjId=<OldSubjectID> #Old SubjectID as register at the scanner consol (must be a pseudonym)
findsession $subjId
DATE=<> #Scanning date YYYY-MM-DD (see findsession output)
BAY=<> #Scanner bay (see findsession output), e.g. bay4
uniqueSubjId=<SubjectUniqueID> #must be a pseudonym, and the key to non-anonymized database must be kept seperatly under restricted access
dcmDir=<> #path to dcm files (see findsession output)
targDir=$dbDir/$uniqueSubjId/$DATE--$BAY--$subjId
### Convert to nii and json
mkdir -p $targDir
dcmunpack \
-extra-info \
-no-exit-on-error \
-dcm2niix \
-createBIDS \
-auto-runseq nii.gz \
-src $dcmDir \
-targ $targDir/nii #-index-in $targDir/nii/log/imagelist.dat
### Add reference to original dcm
ln -s $dcmDir $targDir/dcm #cp -r $dcmDir $targDir/dcm
### Initiate index
cp $targDir/nii/log/series-info.dat $targDir/seriesInfo-$studyId.dat
# then open $targDir/seriesInfo-$studyId.dat and save it as a spreadsheet (libreoffice --calc), and add info related to conversion to BIDS
# don't delete $targDir/seriesInfo-$studyId.dat, it will be usefull for reuse of that session in other studies



##############
### Example ##
##############
## SomePreviousStudy -- rainRoyale -- ssvsasl-p04
studyId=ssvsasl #Name of the study for which data is acquired
subjId=ssvsasl-p04 #Old SubjectID as register at the scanner consol (must be a pseudonym)
findsession $subjId
DATE=2022-10-03 #Scanning date YYYY-MM-DD (see findsession output)
BAY=bay4 #Scanner bay (see findsession output), e.g. bay4
uniqueSubjId=rainRoyale #must be a pseudonym, and the key to non-anonymized database must be kept seperatly under restricted access
dcmDir=/cluster/archive/341/siemens/Prisma_fit-67026-20221003-181053-001040 #path to dcm files (see findsession output)
targDir=$dbDir/$uniqueSubjId/$DATE--$BAY--$subjId
### Convert to nii and json
mkdir -p $targDir
dcmunpack \
-extra-info \
-no-exit-on-error \
-dcm2niix \
-createBIDS \
-auto-runseq nii.gz \
-src $dcmDir \
-targ $targDir/nii #-index-in $targDir/nii/log/imagelist.dat
### Add reference to original dcm
ln -s $dcmDir $targDir/dcm #cp -r $dcmDir $targDir/dcm
### Initiate index
cp $targDir/nii/log/series-info.dat $targDir/seriesInfo-$studyId.dat
# then open $targDir/seriesInfo-$studyId.dat and save it as a spreadsheet (libreoffice --calc), and add info related to conversion to BIDS
# don't delete $targDir/seriesInfo-$studyId.dat, it will be usefull for reuse of that session in other studies
