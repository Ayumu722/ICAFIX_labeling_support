#!/bin/sh

# Set variable values that locate and specify data to process

# establish list of conditions on which to run ICA+FIX
StudyFolder="/mnt/pub/MRI/Human/HCPWG/TrainFIX/multirunFIX"
ScriptFolder="/mnt/user/yamashita/bin"
qc_fix_dir="${StudyFolder}/qc_fix"
job_dir="${qc_fix_dir}/job"
script_output="${qc_fix_dir}/out"
mkdir -p ${qc_fix_dir}
mkdir -p ${job_dir}
mkdir -p ${script_output}
template_file="${ScriptFolder}/template_HCPWG.scene"
SubjData="${StudyFolder}/participants.tsv"   # Space delimited list of subject IDs
Subjlist=$(cut -f 1 $SubjData | sed -e '1d')
CondList="KUHPconcat NIPSconcat RIKENconcat TUconcat"

while read Subject; do
	Subject=`echo $Subject | sed -e "s/[\r\n]\+//g"`
	echo ${Subject}
	echo "#!/bin/sh" >${job_dir}/${Subject}_ICAFIX.sh
	echo "export PATH=/home/yamashita/anaconda3/bin:\$PATH" >>${job_dir}/${Subject}_ICAFIX.sh
	echo "source activate py27" >>${job_dir}/${Subject}_ICAFIX.sh
	echo "fslmaths ${StudyFolder}/${Subject}/MNINonLinear/aparc+aseg.nii.gz -uthr 2 -thr 2 ${StudyFolder}/${Subject}/MNINonLinear/LEFT-CEREBRAL-WHITE-MATTER" >>${job_dir}/${Subject}_ICAFIX.sh
	echo "fslmaths ${StudyFolder}/${Subject}/MNINonLinear/aparc+aseg.nii.gz -uthr 7 -thr 7 ${StudyFolder}/${Subject}/MNINonLinear/LEFT-CEREBELLUM-WHITE-MATTER" >>${job_dir}/${Subject}_ICAFIX.sh
	echo "fslmaths ${StudyFolder}/${Subject}/MNINonLinear/aparc+aseg.nii.gz -uthr 24 -thr 24 ${StudyFolder}/${Subject}/MNINonLinear/CSF" >>${job_dir}/${Subject}_ICAFIX.sh
	echo "fslmaths ${StudyFolder}/${Subject}/MNINonLinear/aparc+aseg.nii.gz -uthr 41 -thr 41 ${StudyFolder}/${Subject}/MNINonLinear/RIGHT-CEREBRAL-WHITE-MATTER" >>${job_dir}/${Subject}_ICAFIX.sh
	echo "fslmaths ${StudyFolder}/${Subject}/MNINonLinear/aparc+aseg.nii.gz -uthr 46 -thr 46 ${StudyFolder}/${Subject}/MNINonLinear/RIGHT-CEREBELLUM-WHITE-MATTER" >>${job_dir}/${Subject}_ICAFIX.sh
	echo "fslmaths ${StudyFolder}/${Subject}/MNINonLinear/CSF.nii.gz -add ${StudyFolder}/${Subject}/MNINonLinear/LEFT-CEREBELLUM-WHITE-MATTER.nii.gz ${StudyFolder}/${Subject}/MNINonLinear/FIXMSK" >>${job_dir}/${Subject}_ICAFIX.sh
	echo "fslmaths ${StudyFolder}/${Subject}/MNINonLinear/FIXMSK.nii.gz -add ${StudyFolder}/${Subject}/MNINonLinear/LEFT-CEREBRAL-WHITE-MATTER.nii.gz ${StudyFolder}/${Subject}/MNINonLinear/FIXMSK" >>${job_dir}/${Subject}_ICAFIX.sh
	echo "fslmaths ${StudyFolder}/${Subject}/MNINonLinear/FIXMSK.nii.gz -add ${StudyFolder}/${Subject}/MNINonLinear/RIGHT-CEREBELLUM-WHITE-MATTER.nii.gz ${StudyFolder}/${Subject}/MNINonLinear/FIXMSK" >>${job_dir}/${Subject}_ICAFIX.sh
	echo "fslmaths ${StudyFolder}/${Subject}/MNINonLinear/FIXMSK.nii.gz -add ${StudyFolder}/${Subject}/MNINonLinear/RIGHT-CEREBRAL-WHITE-MATTER.nii.gz ${StudyFolder}/${Subject}/MNINonLinear/FIXMSK" >>${job_dir}/${Subject}_ICAFIX.sh
	echo "fslmaths ${StudyFolder}/${Subject}/MNINonLinear/FIXMSK.nii.gz -bin ${StudyFolder}/${Subject}/MNINonLinear/FIXMSK" >>${job_dir}/${Subject}_ICAFIX.sh
	for Condition in ${CondList}; do
		DataFolder="${StudyFolder}/${Subject}/MNINonLinear/Results/${Condition}"
		OutFolder="${DataFolder}/fig"
		ICADIM=$(<${StudyFolder}/${Subject}/MNINonLinear/Results/${Condition}/${Condition}_hp2000_dims.txt)   # The number of ICs
		mkdir -p ${OutFolder}
		echo "sed -e 's/KUHP001a/${Subject}/g' ${template_file} > ${DataFolder}/${Subject}_${Condition}.scene" >>${job_dir}/${Subject}_ICAFIX.sh
		# echo "sed -i -e 's/rfmri01AP/${Condition}/g' ${DataFolder}/${Subject}_${Condition}.scene" >>${job_dir}/${Subject}_ICAFIX.sh
		echo "for ica in {1..${ICADIM}};do" >>${job_dir}/${Subject}_ICAFIX.sh
		echo "for i in {1..6};do" >>${job_dir}/${Subject}_ICAFIX.sh
		echo "${ScriptFolder}/workbench/bin_linux64/wb_command -show-scene ${DataFolder}/${Subject}_${Condition}.scene \\" >>${job_dir}/${Subject}_ICAFIX.sh
		echo "\${i} $OutFolder/ICA\${ica}_\${i}.png 2000 1200 -set-map-yoke I \${ica}" >>${job_dir}/${Subject}_ICAFIX.sh
		echo "done" >>${job_dir}/${Subject}_ICAFIX.sh
		echo "convert -delay 200 $OutFolder/ICA\${ica}_*.png ${DataFolder}/${Condition}_hp2000.ica/filtered_func_data.ica/report/ICA\${ica}.gif" >>${job_dir}/${Subject}_ICAFIX.sh
		echo "done" >>${job_dir}/${Subject}_ICAFIX.sh
		echo "python ${ScriptFolder}/icarus-report --labelfilename fix4melview_HCP_hp2000_thr10.txt ${DataFolder}/${Condition}_hp2000.ica \\" >>${job_dir}/${Subject}_ICAFIX.sh
        echo "--html-out ${DataFolder}/qc_icafix.html --csvreport ${DataFolder}/icafix.csv --copy-qcdir ${qc_fix_dir}/${Subject}_${Condition}" >>${job_dir}/${Subject}_ICAFIX.sh
        echo "mkdir -p ${qc_fix_dir}/${Subject}_${Condition}/filtered_func_data.ica/report" >>${job_dir}/${Subject}_ICAFIX.sh
        echo "cp ${DataFolder}/${Condition}_hp2000.ica/fix4melview_HCP_hp2000_thr10_labels_report.html ${qc_fix_dir}/${Subject}_${Condition}/fix4melview_HCP_hp2000_thr10_labels_report.html" >>${job_dir}/${Subject}_ICAFIX.sh
        echo "cp ${DataFolder}/${Condition}_hp2000.ica/fix4melview_HCP_hp2000_thr10.txt ${qc_fix_dir}/${Subject}_${Condition}/fix4melview_HCP_hp2000_thr10.txt" >>${job_dir}/${Subject}_ICAFIX.sh
        echo "cp ${DataFolder}/${Condition}_hp2000.ica/filtered_func_data.ica/report/*.gif ${qc_fix_dir}/${Subject}_${Condition}/filtered_func_data.ica/report/" >>${job_dir}/${Subject}_ICAFIX.sh
        echo "" >>${job_dir}/${Subject}_ICAFIX.sh
        echo "chmod -R a+rwx ${qc_fix_dir}/${Subject}_${Condition}/" >>${job_dir}/${Subject}_ICAFIX.sh
	done
done <<END
$Subjlist
END
