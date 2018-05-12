#!/bin/bash

dim=70
dataFolder="${HOME}/fMRI_data/PTSD_veterans"
melodicFolder="${dataFolder}/analysis/controls_ICA_aroma.gica"
melodicFolderDim="${melodicFolder}/dim${dim}/"
melodicIC="${melodicFolderDim}/meta_melodic_dim${dim}/melodic_IC"

dualRegFolder="${dataFolder}/analysis/ptsd_dual_regression"
#dualRegFolderDim="${dualRegFolder}/dual_regression_dim${dim}.dr"
dualRegFolderDim="${dualRegFolder}/dual_regression_dim${dim}_elbert.dr"
#subjectFiles="${dualRegFolder}/dual_regression_ptsd_filtered.txt"
subjectFiles="${dualRegFolder}/dual_regression_ptsd_filtered_Elbert.txt"
echo ${dualRegFolderDim}
echo "Running dual regression"

dual_regression ${melodicIC} 1 -1 0 ${dualRegFolderDim} `cat ${subjectFiles}`
