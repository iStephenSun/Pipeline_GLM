#!/bin/bash
# Excute Main - in example.sh
. ./test.sh

# bash ./function.sh - start a new sub bash,closed when finished
# . ./  - start in current bash,can do more - subfunction in function.sh
# preprocess_many_runs 20190611_anna_Ying res_20190611_anna_Ying.s1 ../../../raw/doc/neo_Onset/20190611_onset.csv ./runfile.sh 16


load_config ./configuration.txt
main
