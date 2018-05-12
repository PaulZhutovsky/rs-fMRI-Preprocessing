projectFolder="/data/shared/ptsd_police"
dataFolder="${projectFolder}/sub-*"
pathOASISTemplate="${projectFolder}/code/preprocessing/oasis_templates"
#derivativesFolder="${projectFolder}/derivatives/AROMApipeline" see below, does not work with adding /$
ANTSPATH="${projectFolder}/code/ANTs/build/bin"

# for ants parallelization
export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=10

for data in ${dataFolder}; do
	subjID=$(basename ${data})
	echo ${subjID}
	#subjIDzeros=`zeropad ${subjID} 4`
	#echo ${subjIDzeros}
	structFolder="${data}/anat"
	echo ${structFolder}
	strucFile="${structFolder}/${subjID}_T1w"
	echo ${strucFile} 

	# make output dirs in derivatives
	outputFolder="${projectFolder}/derivatives/AROMApipeline/${subjID}/anat"
	#echo "${derivativesFolder}/${subjID}" does not work, but deletes part of path
	echo ${outputFolder}
	mkdir -p -v ${outputFolder}

	
	#original: antsBrainExtraction.sh -d 3 -a ${strucFile}.nii.gz -e ${pathOASISTemplate}/T_template0.nii.gz -m ${pathOASISTemplate}/T_template0_BrainCerebellumProbabilityMask.nii.gz -o ${structFolder}/ants -f ${pathOASISTemplate}/T_template0_BrainCerebellumRegistrationMask.nii.gz -k 1
	
	${ANTSPATH}/antsBrainExtraction.sh -d 3 -a ${strucFile}.nii.gz -e ${pathOASISTemplate}/T_template0.nii.gz -m ${pathOASISTemplate}/T_template0_BrainCerebellumProbabilityMask.nii.gz -o ${outputFolder}/ants -f ${pathOASISTemplate}/T_template0_BrainCerebellumRegistrationMask.nii.gz -k 1
	mv ${outputFolder}/antsBrainExtractionBrain.nii.gz ${outputFolder}/${subjID}_T1w_BFCorr_brain.nii.gz
	mv ${outputFolder}/antsBrainExtractionMask.nii.gz ${outputFolder}/${subjID}_T1w_BFCorr_brain_mask.nii.gz
	mv ${outputFolder}/antsN4Corrected0.nii.gz ${outputFolder}/${subjID}_T1w_BFCorr.nii.gz
	rm -rf ${outputFolder}/ants*
done

