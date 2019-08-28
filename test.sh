#!/bin/bash


onset_fn='../../../raw/doc/neo_Onset/20190611_onset.csv'
expt_file='test.yaml'
cpu=16
output_folder='res '



function main{
for expt in `cat $expt_file | shyaml keys | tr -d '\r' `;do
    echo 'runing' $expt
    output_folder=res.$expt
    echo $output_folder
    # preprocess_many_runs $expt  $output_folder $runfile $cpu

    for run in `cat $expt_file| tr -d '-' | shyaml get-value $expt.runs`;do 
#step1 don'show notes; step2`` run $(command inside) first
        echo "MyAFNI: processing $expt $run"
        time=`date +%H%M`
        echo "onset_file :$onset_fn "
        preprocess_1_run $expt $parent_output_folder $onset_file $run $cpu > ./${expt}_${run}_${time}.log 2>&1
    done 

done

}

# . ./function_pipeline.sh

# bash ./function.sh - start a new sub bash,closed when finished
# . ./  - start in current bash,can do more - subfunction in function.sh