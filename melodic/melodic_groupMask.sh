#!/bin/bash

dataFolder="/data/shared/ptsd_police/derivatives/AROMApipeline"
melodicFolder="${dataFolder}/analysis/groupMaps_metaICA"
melodicTemplate="${melodicFolder}/data_final_all.txt"

iter=1
for funcFile in `cat ${melodicTemplate}`; do	
	echo ${funcFile} 
	echo "Create individual masks"
	
	iterZero=`zeropad ${iter} 4`
	fslmaths ${funcFile} -Tstd -bin ${melodicFolder}/mask_${iterZero} -odt char
	((iter+=1))
done 

echo "Create common mask"
fslmerge -t ${melodicFolder}/maskAll.nii.gz `ls ${melodicFolder}/mask_*.nii.gz`
fslmaths ${melodicFolder}/maskAll -Tmin ${melodicFolder}/mask
imrm ${melodicFolder}/mask_*.nii.gz
