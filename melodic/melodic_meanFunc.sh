#!/bin/bash

dataFolder="/data/shared/ptsd_police/derivatives/AROMApipeline"
melodicFolder="${dataFolder}/analysis/groupMaps_metaICA"
funcFiles="${melodicFolder}/data_final_all.txt"
iter=1

for funcFile in `cat ${funcFiles}`; do	
	echo ${funcFile} 

	echo "Mean individual normalized functionals"
	fslmaths ${funcFile} -Tmean ${melodicFolder}/meanFunc${iter}
	((iter+=1))
done 

echo "Merge mean functionals"
fslmerge -t ${melodicFolder}/meanFunc.nii.gz `ls ${melodicFolder}/meanFunc*[0-9].nii.gz`
imrm ${melodicFolder}/meanFunc*[0-9].nii.gz

echo "Mean mean functionals"
fslmaths ${melodicFolder}/meanFunc.nii.gz -Tmean ${melodicFolder}/meanFunc.nii.gz
