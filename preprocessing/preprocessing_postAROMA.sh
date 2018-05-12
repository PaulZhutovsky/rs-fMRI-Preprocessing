#!/bin/bash

nuisance() {

	fMRIData="$1"
	MNITemplateFolder="$2"
	# extract the subject feat folder path from the fMRIData folder by partition on /ICA_AROMA
	tmp=(${fMRIData///ICA_AROMA/ })
	featFolder=${tmp[0]}
	ANTSPATH="$3"
	#echo ${featFolder}
	echo ${fMRIdata}	

	AROMAFolder="${featFolder}/ICA_AROMA"
	exampleFunc="${featFolder}/reg/example_func.nii.gz"
	structuralBrain="${featFolder}/reg/highres"
	
	tmp2=(${fMRIData///func/ })
	subjFolder=${tmp2[0]}
	subjID=`basename ${subjFolder}`
	structFolder="${dataFolder}/${subjID}/anat"
	echo ${subjID}	

	MNI4mmMask="${MNITemplateFolder}/MNI152_T1_4mm_brain_mask_filled.nii.gz"
	MNI4mm="${MNITemplateFolder}/MNI152_T1_4mm_brain.nii.gz"

	TR=`fslval ${fMRIData} pixdim4`
	# formula for highpass filtering with FSL for > 0.01HZ 	
	# 1/2*f*TR = 1/2*0.01*TR
	sigmaHP=`echo "scale=5; 1/(2*0.01*${TR})" | bc`

	# formula for lowpass filtering with FSL for < 0.1HZ 	
	# 1/2*f*TR = 1/2*0.1*TR
	# sigmaLP=`echo "scale=5; 1/(2*0.1*${TR})" | bc`
 
	
	nuisanceFolder="${featFolder}/ICA_AROMA/nuisance_files"
	mkdir -p ${nuisanceFolder}
	echo ${nuisanceFolder}	

	# 1. We have to go FAST
	echo "T1 segmentation"
	fast -t 1 -n 3 -H 0.1 -I 4 -l 20.0 -N -o ${structuralBrain} ${structuralBrain}
	imrm ${structuralBrain}_mixeltype.nii.gz
	imrm ${structuralBrain}_seg.nii.gz
	imrm ${structuralBrain}_pveseg.nii.gz

	# 2. Threshold masks
	echo "Thresholding masks"
	fslmaths ${structuralBrain}_pve_0.nii.gz -thrp 99 -bin ${structuralBrain}_CSF_thrp99.nii.gz
	fslmaths ${structuralBrain}_pve_2.nii.gz -thrp 99 -bin ${structuralBrain}_WM_thrp99.nii.gz

	# 2.1 Erode masks
	echo "Eroding masks"
	fslmaths ${structuralBrain}_CSF_thrp99.nii.gz -ero ${structuralBrain}_CSF_thrp99_ero1.nii.gz
	fslmaths ${structuralBrain}_WM_thrp99.nii.gz -ero ${structuralBrain}_WM_thrp99_ero1.nii.gz

	# 3. Transform to fMRI space
	echo "WM/CSF mask to EPI space"
	${ANTSPATH}/antsApplyTransforms -d 3 -i ${structuralBrain}_CSF_thrp99_ero1.nii.gz -r ${exampleFunc} -o ${nuisanceFolder}/csf_mask_epi.nii.gz -n MultiLabel -t [${featFolder}/reg/ANTsEPI2T1_BBR.txt,1] -v --float
	${ANTSPATH}/antsApplyTransforms -d 3 -i ${structuralBrain}_WM_thrp99_ero1.nii.gz -r ${exampleFunc} -o ${nuisanceFolder}/wm_mask_epi.nii.gz -n MultiLabel -t [${featFolder}/reg/ANTsEPI2T1_BBR.txt,1] -v --float
	
	# 4. Extract mean CSF/WM time-series
	echo "Calculate mean signal of WM/CSF"
	fslmeants -i ${fMRIData} -o ${nuisanceFolder}/mean_csf.txt -m ${nuisanceFolder}/csf_mask_epi.nii.gz
	fslmeants -i ${fMRIData} -o ${nuisanceFolder}/mean_wm.txt -m ${nuisanceFolder}/wm_mask_epi.nii.gz
	
	# 5. Combine both nuisance files
	echo "Combining files"	
	paste ${nuisanceFolder}/mean_csf.txt ${nuisanceFolder}/mean_wm.txt > ${nuisanceFolder}/nuisance.txt
		
	# 6. Calculating temporal mean 
	echo "Calculate Temporal Mean"
	fslmaths ${fMRIData} -Tmean ${featFolder}/tempMean.nii.gz

	# 7. Nuisance regression
	echo "Nuisance Regression in Progress" 
	fsl_glm -i ${fMRIData} -d ${nuisanceFolder}/nuisance.txt --demean -o ${AROMAFolder}/beta_params.nii.gz --out_res=${AROMAFolder}/denoised_func_data_nonaggr_residual.nii.gz
	imrm ${AROMAFolder}/beta_params.nii.gz		

	# 8. Fixing header information
	echo "Fix header information of residual images"
	fslcpgeom ${fMRIData} ${AROMAFolder}/denoised_func_data_nonaggr_residual.nii.gz

	# 9. Temporal filtering
	echo "Highpass filtering with sigma_hp=${sigmaHP} (>0.01Hz)"	
	fslmaths ${AROMAFolder}/denoised_func_data_nonaggr_residual.nii.gz -bptf ${sigmaHP} -1 -add ${featFolder}/tempMean.nii.gz ${AROMAFolder}/denoised_func_data_nonaggr_residual_highpass.nii.gz

	# 10. Registration to MNI at 4mm
	echo "Register the preprocessed data to MNI at 4mm and mask using an 4mm MNI-mask"
	${ANTSPATH}/antsApplyTransforms -d 3 -e 3 -i ${AROMAFolder}/denoised_func_data_nonaggr_residual_highpass.nii.gz -r ${MNI4mm} -n LanczosWindowedSinc -t ${structFolder}/${subjID}_ANTsT1toMNI1Warp.nii.gz -t ${structFolder}/${subjID}_ANTsT1toMNI0GenericAffine.mat -t ${featFolder}/reg/ANTsEPI2T1_BBR.txt -o ${AROMAFolder}/func_data_aroma_final.nii.gz -v --float
	fslmaths ${AROMAFolder}/func_data_aroma_final.nii.gz -mas ${MNI4mmMask} ${AROMAFolder}/func_data_aroma_final.nii.gz
} 

projectFolder="/data/shared/ptsd_police"

dataFolder="${projectFolder}/derivatives/AROMApipeline"

# Setup ANTs"
ANTSPATH="${projectFolder}/code/ANTs/build/bin"

#ANTSPATH="/data_local/softwares/ANTs/build/bin"
#PATH="${ANTSPATH}:${PATH}"
#export ANTSPATH PATH

# MNI directory
mniTemplates="${projectFolder}/code/preprocessing/icbm152_09c_template/MNI_4mm"

#currentDirectory=`pwd`
#mniTemplates="${currentDirectory}/../preprocessing_structural/mni_templates"


N=10

# Iterate only through the subject for which ICA-AROMA correctly ran through and created an output
for subjAROMAFile in ${dataFolder}/sub-*/func/preproc.feat/ICA_AROMA/denoised_func_data_nonaggr.nii.gz; do
	((i=i%N)); ((i++==0)) && wait
	nuisance ${subjAROMAFile} ${mniTemplates} ${ANTSPATH} &
done


