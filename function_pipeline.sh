#!/bin/bash

function dicom_folder_to_converted_dicom_with_TR {
    echo "dicom_folder_to_converted_dicom_with_TR"
    dicom_folder=$1 # the dicom folder that contains .IMA files
    prefix=$2
    TR=$3
    # tip: Dimon output file name cannot contain '/' character.
    Dimon -quiet -use_obl_origin -infile_prefix $dicom_folder/ -gert_create_dataset -gert_to3d_prefix $prefix -tr $TR -dicom_org
}

function expt_run_to_converted_dicom_with_new_onset_format {
    expt=$1
    run=$2
    onset_file=$3
    anat_dicom_folder=$4
    epi_dicom_folder=$5
    output_folder=$6
    TR=$7
    #sep=$7
    #sep=';'

    subj=${expt}_$run
    onset_file_dir=`dirname $onset_file`

    # anatomy and epi folders are in column 4 and 5 of onset.csv
    # dicom_folder=$onset_file_dir/$anat_dicom_folder;
    dicom_folder="../"$anat_dicom_folder;
    echo "** Structural DICOM folder: $dicom_folder"
    dicom_folder_to_converted_dicom_with_TR $dicom_folder anat_${expt}_$run $TR

    # dicom_folder=$onset_file_dir/$epi_dicom_folder;
    dicom_folder="../"$epi_dicom_folder;
    echo "** EPI DICOM folder: $dicom_folder"
    dicom_folder_to_converted_dicom_with_TR $dicom_folder epi_${expt}_$run $TR

    # move nifti file into the output folder
    mkdir $output_folder
    
    echo "anat_expt_run :anat_${expt}_$run $output_folder"
    3dcopy anat_${expt}_$run $output_folder/anat
    3dcopy epi_${expt}_$run $output_folder/epi
    #mv dimon.* $output_folder/
    #mv GERT* $output_folder/
    /bin/rm anat_${expt}_$run* epi_${expt}_$run*

}


    #method='glm_2nd_block'
    #subj_id="${method}_${expt}_$run"
    #glm_2nd_block $run_folder/epi+orig $run_folder/anat+orig $onset_file $column_stim1_label $subj_id $run_folder $cpu

function glm_2nd_block {
     epi=$1
    anat=$2
    onset_file=$3
    column_stim1_label=$4
    subj_id=$5
    out_dir=$6
    #sep=$7
    cpu=$7

    let "column_stim1_duration=$column_stim1_label+1"
    let "column_stim1_onset=$column_stim1_label+2"

    let "column_stim2_label=$column_stim1_label+3"
    let "column_stim2_duration=$column_stim1_label+4"
    let "column_stim2_onset=$column_stim1_label+5"

    label1=$( grep $expt $onset_file | grep $run | cut -d ',' -f $column_stim1_label )
    duration1=$( grep $expt $onset_file | grep $run | cut -d ',' -f $column_stim1_duration )
    onset1=$( grep $expt $onset_file | grep $run | cut -d ',' -f $column_stim1_onset )
    stim1=${subj_id}_stim1.txt
    echo $onset1 > $stim1

    label2=$( grep $expt $onset_file | grep $run | cut -d ',' -f $column_stim2_label )
    duration2=$( grep $expt $onset_file | grep $run | cut -d ',' -f $column_stim2_duration )
    onset2=$( grep $expt $onset_file | grep $run | cut -d ',' -f $column_stim2_onset )
    stim2=${subj_id}_stim2.txt
    echo $onset2 > $stim2

    method="BLOCK"
    echo "MyAFNI glm_2nd_BLOCK: $epi"
    /bin/rm proc.$subj_id output.$subj_id

    afni_proc.py -subj_id $subj_id \
        -dsets $epi \
        -copy_anat $anat \
        -blocks mask regress \
        -remove_preproc_files \
        -regress_opts_3dD \
            -jobs $cpu \
        -regress_run_clustsim no \
        -regress_stim_times $stim2 \
        -regress_stim_labels $label2 \
        -regress_basis "BLOCK(0.5,1)" \
	-regress_apply_mask
        #-regress_reml_exec \
        #-volreg_align_to MIN_OUTLIER \
        #-mask_dilate 1 \
        #-mask_apply epi \
        #-regress_censor_motion 0.15 \
        #-regress_censor_outliers 0.1 \
            #-gltsym "SYM: $label2 - $label1" \
            #-glt_label 1 ${label2}_subtract_${label1} \

    tcsh -xef ./proc.$subj_id |& tee output.$subj_id
    /bin/rm $out_dir/stats.$subj_id*  # remove old files
    3dcopy $subj_id.results/stats.$subj_id $out_dir/stats.$subj_id
    cp $subj_id.results/*.1D $out_dir/
    cp ${subj_id}_stim*.txt $out_dir/
    /bin/rm -rf $subj_id.results
}


function preprocess_1_run {
    expt=$1
    output_folder=$2
    onset_file=$3
    run=$4
    cpu=$5

    printf "expt: %s\n run: %s\n onset_file: %s\n" $expt $run $onset_file 

    #sep=',' # onset file separator is always ','
    column_expt=1
    column_run=2
    column_desp=3
    column_anat=4
    column_epi=5
    column_dicom_dir=6
    column_TR=7
    column_cycles=8
    column_stim1_label=9

    cycles=`grep $expt $onset_file | grep $run | cut -d ',' -f $column_cycles`
    TR=`grep $expt $onset_file | grep $run | cut -d ',' -f $column_TR`
    dicom_dir=`grep $expt $onset_file | grep $run | cut -d ',' -f $column_dicom_dir`
    anat_dicom_folder=$dicom_dir/`grep $expt $onset_file | grep $run | cut -d ',' -f $column_anat`
    epi_dicom_folder=$dicom_dir/`grep $expt $onset_file | grep $run | cut -d ',' -f $column_epi`
    
    echo "dicom_dir: $dicom_dir"
    echo "anat_dicom_folder: $anat_dicom_folder"
    echo "epi_dicom_folder: $epi_dicom_folder"
    date
    echo "MyAFNI: running $expt $run"

    # =========  step1: create a folder for a run  ===========
    run_folder=$output_folder/${expt}_$run
    mkdir -p $run_folder

    #  =========  step2: convert dicom to afni format
    expt_run_to_converted_dicom_with_new_onset_format $expt $run $onset_file $anat_dicom_folder $epi_dicom_folder $run_folder $TR
    anat=$run_folder/anat+orig
    epi=$run_folder/epi+orig
    
    #  =========  step3: preprocess
    #p19_expt_run_to_preprocessed_folder $anat $epi $run_folder $cycles

    ## step3b: resample anat to epi dimensions
    #resample $run_folder/epi_preprocessed+orig $run_folder/anat_preprocessed+orig resampled_anat $run_folder

    #   =========  step4: create data for an average cycle
    #get_zscore_of_average_cycle_masked $run_folder $cycles epi_preprocessed+orig
    #get_percent_changes_of_average_cycle_masked $run_folder $cycles epi_preprocessed+orig
    #get_MR_signals_of_average_cycle_masked $run_folder $cycles epi_preprocessed+orig


    #   =========  step5: GLM
    method='glm_2nd_block'
    subj_id="${method}_${expt}_$run"
    echo "run_folder: $run_folder"
    glm_2nd_block $run_folder/epi+orig $run_folder/anat+orig $onset_file $column_stim1_label $subj_id $run_folder $cpu

    #method='glm_2nd_tent3'
    #subj_id="${method}_${expt}_$run"
    #glm_2nd_tent3 $run_folder/epi+orig $run_folder/anat+orig $onset_file $column_stim1_label $subj_id $run_folder $cpu

   
    # step6: T-test
    #./s4.ttest9vs9.sh $expt $run $method $cycles >> ${expt}_${run}.log

    #   =========  step7: create p-value and FDR files for each test
    #method='BLOCK'
    #get_p_value_and_FDR $expt $run $method
    #method='TENT10'
    #get_p_value_and_FDR $expt $run $method

    #   =========  step8: plot 

    echo "MyAFNI: finished $expt $run"
    date
}

function preprocess_many_runs {
    expt=$1
    parent_output_folder=$2
    onset_file=$3
    run_file=$4
    cpu=$5

    for run in `grep -v '#' $run_file | cut -d ',' -f 1`; do 
#step1 don'show notes; step2`` run $(command inside) first
        echo "MyAFNI: processing $expt $run"
        time=`date +%H%M`
        echo "onset_file :$onset_file "
        preprocess_1_run $expt $parent_output_folder $onset_file $run $cpu > ${expt}_${run}_${time}.log 2>&1
# output the bug_log
    done 
# Sort out the intermediate files
    mkdir by_products
    mkdir log
    mkdir stim
    
    mv output*${expt}* proc*${expt}* BLOCK*${expt}* TENT*${expt}* by_products/  #* wildcards
    mv *.log log/
    mv *stim*.txt stim/
}


function main {  
   echo "main"
}  



