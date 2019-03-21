#!/bin/bash

# The python package `awscli` is required which can be easily installed using the pip command
# Before running this script be sure you've run `aws s3 configure`
#
# This script syncs a designated directory to our PBS ingest directory on Amazon S3

s3syncDebugging=''; # enabling will disable running of aws sync

localDir='/media/sf_Media_Manager/';
s3BucketName='pbs-ingest'
s3Dir='kawe';
syncDir="${s3BucketName}/kawe/";
exclude=( "*.db" ".DS_Store" "*.jpg" ); # files to be excluded from upload
SAVEIFS=$IFS; # store default IFS variable used by shell
IFS=$(echo -en "\n\b");

# Check for required command
type aws >/dev/null 2>&1 || { echo >&2 "awscli is needed by this script. Learn how to get it at https://aws.amazon.com/cli/ or try \`pip install awscli\`"; exit 1; }

# Rename local files according to directory and episode number
echo; echo "Scanning directories and renaming files...";

# delete junk files
rm "${localDir}/.DS_Store" "${localDir}/Thumbs.db" 2>/dev/null;

for d in `ls -d ${localDir}*/`; do

    d=${d%/}; # remove trailing slash

    echo;
    echo "${d}"; 
    echo "------------------------------------------------";

    # delete junk files
    rm "${d}/.DS_Store" "${d}/Thumbs.db" 2>/dev/null;

    # give them a final name
    for f in `ls -p $d | grep -v /`; do
        
        # remove spaces from filename
        rename 's/ /_/g' $f; 
        nf="${f// /_}";

        # break down the filename
        fName=${nf%%.*};
        fNum=${fName//[^0-9]/};
        fExt=${nf##*.};

        # combine the new filename
        if [[ -z $fNum ]] || [[ $fName =~ '[0-9]' ]] && ! [[ $fName =~ '[a-zA-Z]' ]]; then # if no [episode] number is in the filename
            fNewName="${fName}-"`md5sum ${d}/${f} | awk '{print $1}' | tail -c 10`.${fExt};
        else
            fNewName=${fNum}.${fExt}; #episode number and file ext only
        fi

        if ! [[ ${f} == ${fNewName} ]]; then
            echo "Renaming: ${d}/${f}" ... "${d}/${fNewName}";
            mv "${d}/${f}" "${d}/${fNewName}" 2>/dev/null;
        fi

        if ! [[ -z $s3syncDebugging ]]; then
            # debugging stuff
            echo f is $f;
            echo fName is $fName;
            echo fNum is $fNum;
            echo fExt is $fExt;
            echo fNewName is $fNewName;
        fi

    done;

done;

# Rest IFS before running the awscli command
IFS=$SAVEIFS;

echo; echo "Done renaming files. Will now attempt to sync with your S3 bucket."; echo;

echo "Running the following command:"; echo;
echo "aws s3 sync ${localDir} s3://${syncDir} "`for e in "${exclude[@]}"; do echo --exclude "${e}" ; done;`" --delete";
echo;
# Run the AWS CLI commmand
if [[ -z $s3syncDebugging ]]; then

    echo "Syncing..."

    aws s3 sync ${localDir} s3://${syncDir} `for e in "${exclude[@]}"; do echo "--exclude ${e}" ; done;` --delete
    echo;
    echo "Done syncing.";
    echo;

    # Provide https URLs for the files... dirty but gets the job done.
    echo "#######################################################"
    echo " GETTING URLS FOR ALL FILES IN BUCKET ";
    echo "#######################################################"
    echo; echo "URLs will be saved to urls.txt";
    echo '' > urls.txt;
    sleep 3 # wait a moment before doing ls


    for file in `aws s3 ls s3://${syncDir} --recursive | awk '{print $4}'`; do
        echo "https://${s3BucketName}.s3.amazonaws.com/${file}";
        echo "https://${s3BucketName}.s3.amazonaws.com/${file}" > urls.txt;
    done;

fi

if ! [[ -z $s3syncDebugging ]]; then echo "DEBUGGING ENABLED: sync operation not done."; fi
echo; echo "Done.";
exit;
