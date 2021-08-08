#!/bin/bash

# Author : flashmaddison@seanmaddison.uk
# Copyright (c) Sean Maddison
# Notes:
# 
# - My first attempt at writing a bash script!

# Set deletefiles to true below to remove duplicates

# allow a working directory to be passed in

# TODO
# * Parameterise prioritise largest file

filename=image_dupes_found.txt
deletefiles=false
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
findimagedupes $workingDir > $workingFile

# loop through each line-item in the file

fileLines=$(cat $workingFile)
lineCount=1

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
    thisSize=$(stat --printf="%s" $thisEntry)
    echo - single found item is $thisEntry with file size of $thisSize bytes
    # find largest file
    if [[ "$thisSize" -gt "$prevSize" ]]; then
      fileToKeep=$thisEntry
    fi
  done
  echo - largest file is $fileToKeep, this file will be kept when deleting duplicates
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
      fi
    fi
  done
  echo -----

done
