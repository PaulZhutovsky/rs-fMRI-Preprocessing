#!/bin/bash

projectFolder="/data/shared/ptsd_police"

dataFolder="${projectFolder}/derivatives/AROMApipeline"

# Setup ANTs
ANTSPATH="${projectFolder}/code/ANTs/build/bin"

# Setup c3d
c3dPATH="${projectFolder}/code/c3d/c3d-1.1.0-Linux-gcc64/bin"

# MNI directory
mniTemplates="${projectFolder}/code/preprocessing/icbm152_09c_template" 

# FSL standards
fslStandards="${FSLDIR}/data/standard"

for subjFolder in ${dataFolder}/sub-*; do
	
	subjID=`dirname ${subjFolder}`
	structFolder="${subjFolder}/anat"
	structBrain="${structFolder}/*BFCorr_brain.nii.gz"
	featFolder="${subjFolder}/func/preproc.feat"
	echo $subjID
	echo $structFolder
	echo $structBrain
	echo $featFolder

	# 1. normalization (structural to MNI) in ANTs
	echo "Registering structural to MNI with ANTs"
	${ANTSPATH}/antsRegistrationSyN.sh -d 3 -f ${mniTemplates}/1mm_T1_brain.nii.gz -m ${structBrain} -o ${structFolder}/${subjID}_ANTsT1toMNI -n 12 -j 1
	imrm ${structFolder}/${subjID}_ANTsT1toMNIWarped.nii.gz
	imrm ${structFolder}/${subjID}_ANTsT1toMNIInverseWarped.nii.gz

	# 2. transform BBR coregistration to ANTs
	echo "Transforming BBR coregistration"
	${c3dPATH}/c3d_affine_tool -ref ${structBrain} -src ${featFolder}/reg/example_func.nii.gz ${featFolder}/reg/example_func2highres.mat -fsl2ras -oitk ${featFolder}/reg/ANTsEPI2T1_BBR.txt

	# 2. transform structural to MNI space in 1 and 2mm space
	echo "Transforming structural to MNI in 1mm"
	${ANTSPATH}/antsApplyTransforms -d 3 -i ${structBrain} -r ${fslStandards}/MNI152_T1_1mm_brain.nii.gz -o ${structFolder}/${subjID}_mni_1mm.nii.gz -n BSpline -t ${structFolder}/${subjID}_ANTsT1toMNI1Warp.nii.gz -t ${structFolder}/${subjID}_ANTsT1toMNI0GenericAffine.mat -v --float
	
	echo "Transforming structural to MNI in 2mm"
	${ANTSPATH}/antsApplyTransforms -d 3 -i ${structBrain} -r ${fslStandards}/MNI152_T1_2mm_brain.nii.gz -o ${structFolder}/${subjID}_mni_2mm.nii.gz -n BSpline -t ${structFolder}/${subjID}_ANTsT1toMNI1Warp.nii.gz -t ${structFolder}/${subjID}_ANTsT1toMNI0GenericAffine.mat -v --float
	
	#not necessary right now: fslmaths ${structFolder}/${subjID}_mni_2mm.nii.gz -mas ${fslStandards}/MNI152_T1_2mm_brain_mask.nii.gz ${structFolder}/${subjID}_mni_2mm.nii.gz

	# 3. Transform example_func to MNI with ANTs for checking
	echo "Transforming example_func to MNI with ANTs"
	antsApplyTransforms -d 3 -i ${featFolder}/reg/example_func.nii.gz -r ${fslStandards}/MNI152_T1_2mm.nii.gz -o ${featFolder}/reg/ANTsEPI2MNI.nii.gz -n BSpline -t ${structFolder}/${subjID}_ANTsT1toMNI1Warp.nii.gz -t ${structFolder}/${subjID}_ANTsT1toMNI0GenericAffine.mat -t ${featFolder}/reg/ANTsEPI2T1_BBR.txt -v --float

	#original: antsApplyTransforms -d 3 -i ${featFolder}/reg/example_func.nii.gz -r ${fslStandards}/MNI152_T1_2mm.nii.gz -o ${featFolder}/reg/ANTsEPI2MNI.nii.gz -n BSpline -t ${featFolder}/reg/ANTsT1toMNI1Warp.nii.gz -t ${featFolder}/reg/ANTsT1toMNI0GenericAffine.mat -t ${featFolder}/reg/ANTsEPI2T1_BBR.txt -v --float

done
