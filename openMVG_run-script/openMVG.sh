#!/bin/sh
# @author Pierre-Yves Paranhoën <py.paranthoen@gmail.com>
#
# 09/22/2014
#
# version: 1
#
# A bash script for an openMVG and CMVS-PMVS easy use and computation of process duration.
# Computation is approximative as incrementalSfM needs a manual input for now. So script will wait for your pai selection.
#
# It uses the Clustering Many Multi-View Stereo Genoption (CMVS default value is 20. Change this value to suit your own need)
#
# usage : ./openMVG.sh image_dir output_dir 
#
# image_dir is the input directory where are your images
# output_dir is the directory in which project will be saved
# 
# if output_dir is not present the script will create it 
# 
# the script will create logfile if it does not exist and remove it if it already exists

# Define openMVG AND CMVS-PMVS binaries directory (MUST BE CHANGED TO SUIT YOUR OWN SETUP)
BIN=/usr/local/bin

# Define the openMVG camera sensor width directory (MUST BE CHANGED TO SUIT YOUR OWN SETUP)
CAMERA_SENSOR_WIDTH_DIRECTORY=/usr/local/etc
CAMERA_FILE_DATABASE=$CAMERA_SENSOR_WIDTH_DIRECTORY/cameraGenerated.txt

# CMVS cluster number
cmvs_CN=20

# define name of the logfile
logFile="process.log"

# Script usage

if  [ $# -ne 2 ]
    then
        echo "Usage ./openMVG.sh image_dir output_dir"
    exit 1
fi

INPUT_DIR=$1
OUTPUT_DIR=$2

# make working and logging directories
mkdir -p $OUTPUT_DIR/logs

# Setup log file
if [ -e $OUTPUT_DIR/logs/$logFile ]; then
        echo "Existing log file detected and removed!"
        rm $OUTPUT_DIR/logs/$logFile
fi


echo "Working directories are:" | tee $OUTPUT_DIR/logs/$logFile
echo 
echo "Using $INPUT_DIR as input directory " | tee -a $OUTPUT_DIR/logs/$logFile
echo "Using $OUTPUT_DIR as output directory " | tee -a $OUTPUT_DIR/logs/$logFile
echo "Using $OUTPUT_DIR/logs/$logFile as logging " | tee -a $OUTPUT_DIR/logs/$logFile
echo "------------------------------------------" | tee -a $OUTPUT_DIR/logs/$logFile
echo

                

start_Time_Process(){
 # UNIX timestamp concatenated with nanoseconds
 TS="$(date +%s%N)"
}     

end_Time_Process(){
    # Time interval in nanoseconds
    TE="$(($(date +%s%N)-TS))"
    # Seconds
    S="$((TE/1000000000))"
    # Milliseconds
    M="$((TE/1000000))"
    result=" "$((S/86400))"  "$((S/3600%24))" "$((S/60%60))" "$((S%60))" "${M}" "
}                      

createLIST(){
# STEP 1: Intrisics analysis
         
    start_Time_Process 
    echo "run for Intrisic analysis: openMVG_main_CreateList -i ${INPUT_DIR} -d $CAMERA_FILE_DATABASE -o ${OUTPUT_DIR}/matches"
    ${BIN}/openMVG_main_CreateList -i ${INPUT_DIR} -d $CAMERA_FILE_DATABASE -o ${OUTPUT_DIR}/matches
    echo 
    end_Time_Process 
    echo 
    printf "STEP 1: Process Intrisic analysis - openMVG_main_CreateList took: %02d:%02d:%02d:%02d.%03d\n" $result  | tee -a $OUTPUT_DIR/logs/$logFile
    # store end time
    result_step1=$TE
}

computeMatches(){
# STEP 2: Compute matches
    
    start_Time_Process
    echo "run for compute matches: openMVG_main_computeMatches -g f -p 0.01 -r 0.8 -i ${INPUT_DIR} -o ${OUTPUT_DIR}/matches"    
    ${BIN}/openMVG_main_computeMatches -g f -p 0.01 -r 0.8 -i ${INPUT_DIR} -o ${OUTPUT_DIR}/matches    
    echo
    end_Time_Process
    echo
    printf "STEP 2: Process compute matches - openMVG_main_computeMatches took: %02d:%02d:%02d:%02d.%03d\n" $result | tee -a $OUTPUT_DIR/logs/$logFile
    # store end time
    result_step2=$TE
}

incrementalSfM(){
# STEP 3: Do reconstruction
    
    start_Time_Process
    echo "run for Incremental Reconstrution:  openMVG_main_IncrementalSfM -c 1 -i ${INPUT_DIR} -m ${OUTPUT_DIR}/matches -o ${OUTPUT_DIR}/outReconstruction"
    ${BIN}/openMVG_main_IncrementalSfM -i ${INPUT_DIR} -m ${OUTPUT_DIR}/matches -o ${OUTPUT_DIR}/outReconstruction
    echo
    end_Time_Process
    echo
    printf "STEP 3: Process Incremental Reconstruction -  openMVG_main_IncrementalSfM took: %02d:%02d:%02d:%02d.%03d\n" $result | tee -a $OUTPUT_DIR/logs/$logFile
    # store end time
    result_step3=$TE
}

openMVG2PMVS(){
# STEP 4: Export to CMVS-PMVS
    
    start_Time_Process
    echo "Export to CMVS-PMVS: openMVG_main_openMVG2PMVS -i ${OUTPUT_DIR}/outReconstruction/SfM_output/ -o ${OUTPUT_DIR}/outReconstruction/SfM_output/"
    ${BIN}/openMVG_main_openMVG2PMVS -i ${OUTPUT_DIR}/outReconstruction/SfM_output/ -o ${OUTPUT_DIR}/outReconstruction/SfM_output/
    echo
    end_Time_Process
    echo
    printf "STEP 4: Process Export to CMVS-PMVS - openMVG_main_openMVG2PMVS took: %02d:%02d:%02d:%02d.%03d\n" $result | tee -a $OUTPUT_DIR/logs/$logFile | tee -a $OUTPUT_DIR/logs/$logFile
    # store end time
    result_step4=$TE
}

cmvs_pmvs(){
# STEP 5: Run CMVS-PMVS
    
    start_Time_Process

    ${BIN}/cmvs ${OUTPUT_DIR}/outReconstruction/SfM_output/PMVS/ $cmvs_CN

    ${BIN}/genOption ${OUTPUT_DIR}/outReconstruction/SfM_output/PMVS/
    #
    for op in ${OUTPUT_DIR}/outReconstruction/SfM_output/PMVS/option-* ;
	do
	option_files=`ls -1 $op | sed 's#.*/##'`
	echo "Processing pmvs2 ${OUTPUT_DIR}/outReconstruction/SfM_output/PMVS/ $option_files"
	pmvs2 ${OUTPUT_DIR}/outReconstruction/SfM_output/PMVS/ $option_files
    done
    #
    echo
    end_Time_Process
    echo
    printf "STEP 5: Process CMVS-PMVS took: %02d:%02d:%02d:%02d.%03d\n" $result | tee -a $OUTPUT_DIR/logs/$logFile
    # store end time
    result_step5=$TE
}

finalDuration(){
# The whole 3D reconstruction process duration
# testing purpose: comment/uncomment
#    finalProcessDuration=$(($result_step1 + $result_step1))

    # compute final duration
    finalProcessDuration=$(($result_step1 + $result_step2 + $result_step3 + $result_step4 + $result_step5))
    
    # Seconds
    S="$((finalProcessDuration/1000000000))"
    #    # Milliseconds
    M="$((finalProcessDuration/1000000))"
    # conversion in human readable
    finalProcessDurationHumanFormat=" "$((S/86400))"  "$((S/3600%24))" "$((S/60%60))" "$((S%60))" "${M}" "
    echo
    echo
    echo "--------------------"  | tee -a $OUTPUT_DIR/logs/$logFile
    printf "The whole detection and 3D reconsruction process took: %02d:%02d:%02d:%02d.%03d\n" $finalProcessDurationHumanFormat | tee -a $OUTPUT_DIR/logs/$logFile
}

openMVG2CMPMVS(){
    # this is optional and only if you want to run CMPMVS
    echo "Process export to CMPMVS - ${BIN}/openMVG_main_openMVG2CMPMVS -i ${OUTPUT_DIR}/outReconstruction/SfM_Output/ -o ${OUTPUT_DIR}/outReconstruction/SfM_Output/"
    ${BIN}/openMVG_main_openMVG2CMPMVS -i ${OUTPUT_DIR}/outReconstruction/SfM_Output/ -o ${OUTPUT_DIR}/outReconstruction/SfM_Output/
    
}

# run openMVG suite
createLIST
computeMatches
incrementalSfM
openMVG2PMVS
cmvs_pmvs
finalDuration
#openMVG2CMPMVS