This is a bash script that uses Amazon's python package, `awscli`, to sync local files to Amazons S3. **WARNING!**: This script will delete files from the S3 bucket if they don't exist on the local file system.

Once `awscli` is installed (e.g. `pip install awscli`) just run `aws s3 configure` which will request your credentials for the S3 bucket. Then choose a local directory to store files you want to sync with the S3 bucket. A suggested heirarchy is shown below. Keep in mind that all episodes will be renamed to their episode number followed by a file extension as shown below.

```
main_sync_directory
│
└───show-name
│   │   episode-001.mp4 (will be renamed to 001.mp4)
│   │   episode-001.scc (will be renamed to 001.scc)
│   
└───show-name-of-another
│   │   episode-1002.mp4 (will be renamed to 1002.mp4)
│   │   episode-1002.scc (will be renamed to 1002.scc)
│   │   episode-1003.mp4 (will be renamed to 1003.mp4)
│   │   episode-1003.scc (will be renamed to 1003.scc)
│   
└───show-name-yet-one-more-show
    │   episode-1201.mp4 (will be renamed to 1201.mp4)
    │   episode-1201.scc (will be renamed to 1201.scc)

```

## Caution!!!
This script will delete files that do not exist on your local machine. This includes files that have been renamed. They will be deleted from the S3 bucket and re-uploaded with the new file name.
