#!/bin/bash

# The python package `awscli` is required which can be easily installed using the pip command
# Before running this script be sure you've run `aws s3 configure`
#
# This script syncs a designated directory to our PBS ingest directory on Amazon S3

localDir='/media/sf_Media_Manager/';
s3Dir='pbs-ingest/kawe/';
exclude=( "*.db" ".DS_Store" "*.jpg" ); # files to be excluded from upload

# Rename local files according to directory and episode number

echo "Checking for files that need renaming.";
echo;

for d in `ls -d ${localDir}*/`; do

    d=${d%/}; # remove trailing slash

    echo;
    echo "${d} ############################################";
    echo;

    # delete junk files
    rm "${d}/.DS_Store" "${d}/Thumbs.db" 2>/dev/null;

    # rename each file
    for f in `ls -p $d | grep -v /`; do

        # break down the filename
        fName=${f%%.*};
        fNum=${fName//[^0-9]/};
        fExt=${f##*.};
        # combine the new filename
        # fNewName=${d##*/}-${fNum}.${fExt}; # show name, episode num, and ext
        fNewName=${fNum}.${fExt}; #episode number and file ext only

        mv "${d}/${f}" "${d}/${fNewName}"

        # debugging stuff
        #echo f is $f;
        #echo fName is $fName;
        #echo fNum is $fNum;
        #echo fExt is $fExt;
        #echo fNewName is $fNewName;

    done;

done;

echo; echo "Done renaming files. Will now attempt to sync with your S3 bucket."; echo;

echo "Running the following command:"; echo;
echo "aws s3 sync ${localDir} s3://${s3Dir} "`for e in "${exclude[@]}"; do echo --exclude "${e}" ; done;`" --delete";
echo;

# Run the AWS CLI commmand
aws s3 sync ${localDir} s3://${s3Dir} `for e in "${exclude[@]}"; do echo --exclude "${e}" ; done;` --delete
