#!/usr/bin/env bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: BSD-3-Clause
#

show_help() {
	echo "
         usage: $0 DURATION LOG_DIRECTORY PLATFORM [--xeon-memory-only]         
        "
}

#echo "DEBUG: Params $@"

DURATION=$1
LOG_DIRECTORY=$2
PLATFORM=$3
#SOURCE_DIR=$(dirname "$(readlink -f "$0")")
PCM_DIRECTORY=/opt/intel/pcm/build/bin
source ../get-gpu-info.sh

test_run=0
if [ "$4" == "--xeon-memory-only" ]
then
  test_run=1
fi

is_xeon=`lscpu | grep -i xeon | wc -l`

echo "Starting platform data collection"
#if this is the first run, collect all the metrics
if [ $test_run -eq 0 ]
then
  echo "Starting main data collection"
  timeout "$DURATION" sar 1 >& $LOG_DIRECTORY/cpu_usage.log &
  timeout "$DURATION" free -s 1 >& $LOG_DIRECTORY/memory_usage.log &
  timeout "$DURATION" sudo iotop -o -P -b >& $LOG_DIRECTORY/disk_bandwidth.log &
  
  if [ "$is_xeon"  == "1"  ]
  then
    echo "Starting xeon pcm-power collection"
    timeout "$DURATION" sudo $PCM_DIRECTORY/pcm-power >& $LOG_DIRECTORY/power_usage.log &
  else
    #/opt/intel/pcm/build/bin/pcm 1 -silent -nc -nsys -csv=$LOG_DIRECTORY/pcm.csv &
    #pcm_has_data=`wc -l yolov5s_efficientnet_i7-12700H_4objs_igpu_streamdensity/data/pcm.csv | cut -d ' ' -f 1`
    echo "Starting non-xeon pcm collection"
    modprobe msr
    # process list to see if any dangling pcm background processes to kill
    pcm_pids=($(ps aux | grep pcm | grep -v grep | awk '{print $2}'))
    if [ -z "$pcm_pids" ]
    then
      echo "no dangling pcm background processes to clean up"
    else
      for pid in "${pcm_pids[@]}"
      do
        echo "cleaning up dangling pcm $pid"
        sudo kill -9 "$pid"
      done
    fi
    timeout "$DURATION" sudo $PCM_DIRECTORY/pcm 1 -silent -nc -nsys -csv=$LOG_DIRECTORY/pcm.csv &
    echo "DEBUG: pcm started collecting"
  fi
      
  # DGPU pipeline and Flex GPU Metrics
  if [ "$PLATFORM" == "dgpu" ] && [ $HAS_ARC == 0 ] 
  then
    metrics=0,5,22,24,25
    # Check for up to 4 GPUs e.g. 300W max 
    if [ -e /dev/dri/renderD128 ]; then
      echo "==== Starting xpumanager capture (gpu 0) ===="
      timeout "$DURATION" sudo xpumcli dump --rawdata --start -d 0 -m $metrics -j > ${LOG_DIRECTORY}/xpum0.json &
    fi
    if [ -e /dev/dri/renderD129 ]; then
      echo "==== Starting xpumanager capture (gpu 1) ===="
      timeout "$DURATION" sudo xpumcli dump --rawdata --start -d 1 -m $metrics -j > ${LOG_DIRECTORY}/xpum1.json &
    fi
    if [ -e /dev/dri/renderD130 ]; then
      echo "==== Starting xpumanager capture (gpu 2) ===="
      timeout "$DURATION" sudo xpumcli dump --rawdata --start -d 2 -m $metrics -j > ${LOG_DIRECTORY}/xpum2.json &
    fi
    if [ -e /dev/dri/renderD131 ]; then
      echo "==== Starting xpumanager capture (gpu 4) ===="
      timeout "$DURATION" sudo xpumcli dump --rawdata --start -d 3 -m $metrics -j > ${LOG_DIRECTORY}/xpum3.json &
    fi
  # DGPU pipeline and  Arc GPU Metrics
  elif [ "$PLATFORM" == "dgpu" ] && [ $HAS_ARC == 1 ]
  then
    echo "==== Starting igt arc ===="
    # Arc is always on Core platform and although its GPU.1, the IGT device is actually 0
    # Collecting both 
    timeout $DURATION ../docker-run-igt.sh 0
    timeout $DURATION ../docker-run-igt.sh 1

  # CORE pipeline and iGPU/Arc GPU Metrics
  elif [ "$PLATFORM" == "core" ]
  then
    if [ $HAS_ARC == 1 ]
    then
      # Core can only have at most 2 GPUs 
      timeout $DURATION ../docker-run-igt.sh 0
      timeout $DURATION ../docker-run-igt.sh 1
    else
      timeout $DURATION ../docker-run-igt.sh 0
    fi    
  fi
#if this is the second run, collect memory bandwidth data only
else
  if [ "$is_xeon"  == "1"  ]
  then
    timeout "$DURATION" sudo $PCM_DIRECTORY/pcm-memory 1 -silent -nc -csv=$LOG_DIRECTORY/memory_bandwidth.csv &
  fi 
fi

if [ "$DURATION" == "0" ]
then
	echo "Data collection running until max stream density is reached"
else	
	echo "Data collection will run for $DURATION seconds"
fi
sleep $DURATION

#echo "stopping docker containers" 
#./stop_server.sh
#echo "stopping data collection..."
#sudo pkill -f iotop
#sudo pkill -f free
#sudo pkill -f sar
#sudo pkill -f pcm-power
#sudo pkill -f pcm
#sudo pkill -f xpumcli
#sudo pkill -f intel_gpu_top
#sleep 2

#if [ -e ../results/r0.jsonl ]
#then
#  echo "Copying data for collection scripts...`pwd`"

#  sudo cp -r ../results .
#  sudo mv results/igt* $LOG_DIRECTORY
#  sudo mv results/pipeline* $LOG_DIRECTORY
#  sudo python3 ./results_parser.py >> meta_summary.txt
#  sudo mv meta_summary.txt $LOG_DIRECTORY
#else
#  echo "Warning no data found for collection!"
#fi
