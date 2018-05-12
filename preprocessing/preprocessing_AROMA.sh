#!/bin/bash

aroma() {
	subjFullFolder="$1"
	dataFolder="$2"
	AROMAScript="$3"

	subjFolder=$(basename "${subjFullFolder}")
	echo ${subjFolder}

	featFolder="${dataFolder}/${subjFolder}/func/preproc.feat" # what do we want as output folder?
	fMRIData="${featFolder}/filtered_func_data.nii.gz"
	mcFiles="${featFolder}/mc/prefiltered_func_data_mcf.par"
	exampleFunc="${featFolder}/reg/example_func.nii.gz"
	echo ${fMRIData}

	structFolder="${dataFolder}/${subjFolder}/anat"
	echo ${structFolder}

	# 1. Create Mask (creates func.nii.gz (brain-extracted) and func_mask.nii.gz, we only need the latter und will remove the former)
	echo "Creating Func Mask!"
	bet ${exampleFunc} ${featFolder}/reg/func -f 0.3 -n -m -R
	imrm ${featFolder}/reg/func.nii.gz

	# 2. run AROMA
	echo "Running AROMA" 
	echo ${fMRIData}
	python $AROMAScript -in ${fMRIData} -out ${featFolder}/ICA_AROMA -mc ${mcFiles} -m ${featFolder}/reg/func_mask.nii.gz -affmat ${featFolder}/reg/ANTsEPI2T1_BBR.txt -affmat2 ${structFolder}/${subjFolder}_ANTsT1toMNI0GenericAffine.mat -warp ${structFolder}/${subjFolder}_ANTsT1toMNI1Warp.nii.gz
}

#dataFolder=${HOME}/fMRI_data/PTSD_veterans
#AROMAScript=${dataFolder}/code/ICA-AROMA_ANTS/ICA_AROMA.py
#session=ses-T0
#subjectToInclude='sub-ptsd*'
#N=10

projectFolder="/data/shared/ptsd_police"
dataFolder="${projectFolder}/derivatives/AROMApipeline"
AROMAScript="${projectFolder}/code/ICA_AROMA/ICA_AROMA.py"
subjectToInclude='sub-*'
N=5

for subjFullFolder in ${dataFolder}/${subjectToInclude}; do
	((i=i%N)); ((i++==0)) && wait 
	aroma ${subjFullFolder} ${dataFolder} ${AROMAScript} &
done



