#!/bin/bash

run_feat() {

	SubjFolder="$1"
	DerivativesFolder="$2"
	FeatTemplate="$3"
	
	echo "Start FEAT on: ${SubjFolder}"
	# get only the subject-id part (e.g. sub-control01)
	SubjID=`basename ${SubjFolder}`
	FuncFolder="${SubjFolder}/func"
	FuncData=`ls ${FuncFolder}/*task-rest_bold.nii.gz`
	FuncTR=`fslval ${FuncData} pixdim4`
	FuncNVol=`fslval ${FuncData} dim4`
	FuncPreprocFolder="${DerivativesFolder}/${SubjID}/func"
	mkdir -p ${FuncPreprocFolder}

	echo ${SubjID}
	echo ${FuncPreprocFolder}

	StructBrain=`ls ${DerivativesFolder}/${SubjID}/anat/*BFCorr_brain.nii.gz`
	# now remove file-extension (.nii.gz) since feat doesn't like it in their file names, unfortunatenly doesn't give you the full path automatically (i.e. only sub-control01_T1w_BFCorr_brain)
	StructBrain=`basename ${StructBrain} .nii.gz`
	StructBrain="${DerivativesFolder}/${SubjID}/anat/${StructBrain}"
	
	echo ${StructBrain}

	# Parameters which will be substituted into the template file
	FEATBASEDIR=${FuncPreprocFolder}
	FEAT4DRSDATA=${FuncData}
	FEATT1BRAIN=${StructBrain}
	FEATTR=${FuncTR}
	FEATNVOL=${FuncNVol}
	
	sed -e "s@FEATBASEDIR@${FEATBASEDIR}@g" \
	    -e "s@FEATTR@${FEATTR}@g" \
	    -e "s@FEATNVOL@${FEATNVOL}@g" \
	    -e "s@FEAT4DRSDATA@${FEAT4DRSDATA}@g" \
	    -e "s@FEATT1BRAIN@${FEATT1BRAIN}@g" \
	    ${FeatTemplate} > ${FEATBASEDIR}/design_preproc_feat_preAROMA.fsf	

	feat ${FEATBASEDIR}/design_preproc_feat_preAROMA.fsf					
}



DataFolder="/data/shared/ptsd_police"
DerivativesFolder="${DataFolder}/derivatives/AROMApipeline"
#mkdir -p ${DerivativesFolder}

# FEAT template
FeatTemplate="${DataFolder}/code/preprocessing/design_preproc_TEMPLATE.fsf"

for SubjFolder in ${DataFolder}/sub-*; do
	run_feat ${SubjFolder} ${DerivativesFolder} ${FeatTemplate}
done
