#!/bin/bash

motionOutlier() {
	dataFolder="$1"
	subjFullFolder="$2"

	subjID=$(basename "${subjFullFolder}")
	echo ${subjID}

	funcFile="${projectFolder}/${subjID}/func/${subjID}_task-rest_bold.nii.gz" #raw data file
	echo ${funcFile}
	
	featFolder="${dataFolder}/${subjID}/func/preproc.feat"
	echo ${featFolder}

	# 1. 
	echo "Calculate FD_Jenkings"
	fsl_motion_outliers -i ${funcFile} -o ${featFolder}/mc/fd_jenkins_EV.txt -s ${featFolder}/mc/fd_jenkins.txt -p ${featFolder}/mc/fd_jenkins.png --fdrms
	
	# 2.
	echo "Calculate FD_Power"
	fsl_motion_outliers -i ${funcFile} -o ${featFolder}/mc/fd_power_EV.txt -s ${featFolder}/mc/fd_power.txt -p ${featFolder}/mc/fd_power.png --fd	

	# 2.
	echo "Calculate DVARS"
	fsl_motion_outliers -i ${funcFile} -o ${featFolder}/mc/dvars_EV.txt -s ${featFolder}/mc/dvars.txt -p ${featFolder}/mc/dvars.png --dvars
}

projectFolder="/data/shared/ptsd_police"
dataFolder="${projectFolder}/derivatives/AROMApipeline"

#session=ses-T0

subjectToInclude='sub-*'
N=10

for subjFullFolder in ${dataFolder}/${subjectToInclude}; do
	((i=i%N)); ((i++==0)) && wait
	motionOutlier ${dataFolder} ${subjFullFolder} &
done
