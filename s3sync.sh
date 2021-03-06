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
exclude=("*.db" ".DS_Store" "*.jpg"); # files to be excluded from upload
junkFiles=(".DS_Store" "Thumbs.db");
SAVEIFS=$IFS; # store default IFS variable used by shell
IFS=$(echo -en "\n\b");

############################################################
# Removes $junkFiles from specified directory
# $1 sould be the directory
############################################################
function rm_junkfiles() {
    [[ -z $junkFiles ]] && return; # no files specified
    [[ -z $1 ]] && return; # no directory provided

    for f in ${junkFiles[@]}; do
        rm ${1}/${f} 2>/dev/null &
    done;
}


# Check for required command
type aws >/dev/null 2>&1 || {
    echo >&2 "awscli is needed by this script. Learn how to get it at https://aws.amazon.com/cli/ or try \`pip install awscli\`";
    exit 1;
}

rm_junkfiles ${localDir};

# Rename local files according to directory and episode number
for d in `ls -d ${localDir}*/`; do

    d=${d%/}; # remove trailing slash
    basename="$(basename $d)";

    echo;
    echo "${d}"; 
    echo "------------------------------------------------";

    if ! [[ -z $s3syncDebugging ]]; then
        # debugging stuff
        echo "localDir: ${localDir}; d: ${d}; basename: ${basename}";
    fi

    rm_junkfiles $d;

    # give them a final name
    for f in `ls -p $d | grep -v /`; do # loop through only files and no dirs

        read fName fNum fExt nf <<< ''; # init clean vars
        
        nf=`echo "${f}" | sed -e 's/ /-/g' -e 's/[\(\)]//g'`;

        # break down the filename
        fName=${nf%%.*};
        fExt=${nf##*.};
        if [ "$basename" == "previews" ] || [ "$basename" == "other" ]; then
            fNum='';
        else
            fNum=${fName//[^0-9]/};
        fi

        # combine the new filename
        if [[ -z $fNum ]]; then # if no [episode] number is in the filename
            md5=`md5sum ${d}/${f} | awk '{print $1}' | tail -c 10`;

            # Check for an MD5 match
            if [ "${md5}" = `echo $fName | tail -c 10` ]; then
                echo "An MD5 sum match was found. Skipping ${f}";
                fNewName='';
            else
                fNewName="${fName}-${md5}.${fExt}";
            fi
        else
            fNewName=${fNum}.${fExt}; #episode number and file ext only
        fi

        if [[ "${f}" != "${fNewName}" && ! -z $fNewName ]]; then
            echo "Renaming: ${f}" ... "${fNewName}";
            mv "${d}/${f}" "${d}/${fNewName}" 2>/dev/null;
        fi

        if ! [[ -z $s3syncDebugging ]]; then
            # debugging stuff
            echo "f is ${f}; fName is ${fName}; fNum is ${fNum}; fExt is ${fExt}; md5 is ${md5}; fNewName is ${fNewName};";
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
        echo "https://${s3BucketName}.s3.amazonaws.com/${file}" >> urls.txt;
    done;

fi

[[ ! -z $s3syncDebugging ]] && echo "DEBUGGING ENABLED: sync operation not done."; 
echo; echo "Done.";
exit;
