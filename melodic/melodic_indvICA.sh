#!/bin/bash

indvMelodic() {
	run="$1"
	input_1="$2"
	input_2="$3"
	input_3="$4"
	input_4="$5"	
	melodicMainFolder="$6"
	bgImage="$7"
	dim="$8"
	
	overlapMask=${melodicFolder}/mask.nii.gz	

	# 1, create output folder based on the run
	outputFolder="${melodicMainFolder}/indv_melodic${run}"
	mkdir -p ${outputFolder}
	echo ${outputFolder}	
	inputs="${outputFolder}/filelist${run}.txt"
	echo ${inputs}

	group1="${outputFolder}/filelist${run}_group1.txt"
	group2="${outputFolder}/filelist${run}_group2.txt"
	group3="${outputFolder}/filelist${run}_group3.txt"
	group4="${outputFolder}/filelist${run}_group4.txt"

	# 2. shuffle the input filelists and store them under the output folder
	# cat ${mainInput} | shuf > ${inputs}	
	cat ${input_1} | shuf > ${group1}
	cat ${input_2} | shuf > ${group2}
	cat ${input_3} | shuf > ${group3}
	cat ${input_4} | shuf > ${group4}
	
	# 3. extract the first 10 subjects and resave only them, then remove the group filelists
	head -10 ${group1} > ${inputs}
	head -10 ${group2} >> ${inputs}
	head -10 ${group3} >> ${inputs}
	head -10 ${group4} >> ${inputs}

	rm ${group1}
	rm ${group2}
	rm ${group3}
	rm ${group4}
	
	fMRIData=`head -1 ${inputs}`
	TR=`fslval ${fMRIData} pixdim4`
	echo ${TR}	
	
	# 4. run melodnic
	melodic -i ${inputs} -o ${outputFolder} -a concat --sep_vn -m ${overlapMask} --disableMigp --mmthresh=0.5 --tr=${TR} --bgimage=${bgImage} -d ${dim} --report -v
} 

dim=70

dataFolder="/data/shared/ptsd_police/derivatives/AROMApipeline"
melodicFolder="${dataFolder}/analysis/groupMaps_metaICA"
saveFolder="${melodicFolder}/dim${dim}"
mkdir -p ${saveFolder}
bgImage="${melodicFolder}/bg_imageMNI4mm.nii.gz"

fileList_CM="${melodicFolder}/data_final_control_male.txt"
fileList_CF="${melodicFolder}/data_final_control_female.txt"
fileList_PM="${melodicFolder}/data_final_ptsd_male.txt"
fileList_PF="${melodicFolder}/data_final_ptsd_female.txt"

N=10

for run in {01..25}; do
	((i=i%N)); ((i++==0)) && wait
	indvMelodic ${run} ${fileList_CM} ${fileList_CF} ${fileList_PM} ${fileList_PF} ${saveFolder} ${bgImage} ${dim} &
done



