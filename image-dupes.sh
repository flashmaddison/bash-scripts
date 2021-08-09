#!/bin/bash

# Author : intbonus@seanmaddison.uk
# Copyright (c) Sean Maddison
# Notes:
# 
# - My first attempt at writing a bash script!

# Notes
# -----
# Set deletefiles to true below to remove duplicates when found, set to false just to log
# Default image duplicate threshold is 90%, change dupeThreshold below to alter this

# TODO
# * Parameterise prioritise largest file
# * log file stuff

filename=image_dupes_found.txt
deletefiles=false
LOG_FILE=/var/log/image-dupes.sh.log
echo -e "! deletefiles is set to $deletefiles"


if [ -z "$1" ]
then
  echo " - no working directory provided, defaulting to current directory"
  workingDir=./
else
  echo " - working directory provided"
  workingDir=$1;
fi

echo "working directory is $workingDir"

# write duplicates to file
workingFile=$workingDir/$filename

# Write findimagedupes output to a file so we can work through it
echo Writing findimagedupes output to $workingFile
findimagedupes -t $dupeThreshold $workingDir > $workingFile

# loop through each line-item in the file

fileLines=$(cat $workingFile)
lineCount=1
dupesFound=0
deletedFiles=0
# Set newlines to be terminator for the loop, not spaces
IFS=$'\n'

for line in $fileLines
do
  prevSize=0
  echo "line $lineCount is $line"
  lineCount=$((lineCount+1))

  # split each line by whitespace, loop through and check each file size, select the largest file to keep
  IFS=' ' read -ra thisDuplicate <<< "$line"
  for thisEntry in "${thisDuplicate[@]}"
  do
    dupesFound=$((dupesFound+1))
    thisSize=$(stat --printf="%s" $thisEntry)
    echo - single found item is $thisEntry with file size of $thisSize bytes
    # find largest file
    if [[ "$thisSize" -gt "$prevSize" ]]; then
      fileToKeep=$thisEntry
    fi
  done
  echo - largest file is $fileToKeep, this file will be kept when deleting duplicates
  dupesFound=$((dupesFound-1))
  echo ---

  # now find the files to delete
  IFS=' ' read -ra thisDuplicate <<< "$line"
  for thisEntry in "${thisDuplicate[@]}"
  do
    # find largest file
    if [[ "$thisEntry" != "$fileToKeep" ]]; then
      echo - file to be deleted is $thisEntry
      # delete file if --delete is passed in
      if [[ "$deletefiles" == "true" ]]; then
        echo -e " - deleting duplicates"
        rm -v $thisEntry
        deletedFiles=$((deletedFiles+1))
      fi
    fi
  done
  echo -----
done
echo -e " - $dupesFound duplicates found, not including largest original file"
echo -e " - $deletedFiles files deleted."
