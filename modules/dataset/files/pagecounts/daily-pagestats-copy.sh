#!/bin/bash

# Copy pagecounts/projectcounts files from source host
# to datasets web server
# Run out of cron on a snapshot host every hour

# Requirements:
#
# The following scripts need to be in /usr/local/bin:
# generate-pagecount-main-index.sh
# generate-pagecount-year-index.sh
# generate-pagecount-year-month-index.sh
#
# The user that this script will run as should have an
# authorized key file set up on the remote host and the
# corresponding private key file on the local host.

# ways this script can go wrong:
# 1) it can refuse to run thinking there is a job already running
# when it's an unrelated long-running rsync from the same remote directory;
# in this case a later run will complete normally
# 2) a previous run could take so long to do the md5 step that it
# finishes after this run and new hashes don't show up in the md5s file;
# in that case the following run should fill them in

usage() {
    echo "This script copies pagecounts and projectcounts files from the host"
    echo "on which they are generated, to a directory on our datasets webserver."
    echo "These files contain page view information for all public Wikimedia projects."
    echo
    echo "Usage: $0 username sshkeyfile remotehost remotedir localdir webdir"
    echo
    echo "username   -- the name of the user to connect as to the remote host"
    echo "sshkeyfile -- the name of the private key file to be used for rsync ssh"
    echo "remotehost -- the fqnd of the remote host to retrieve from"
    echo "remotedir  -- the remote directory in which the pagecount files are found"
    echo "localdir   -- the local directory used as a staging area for retrieving files"
    echo "webdir     -- the web directory under which directories for each year are"
    echo "              created, containing directories per month with the pagecounts"
    echo
    echo "For example:"
    echo -n "$0 datasets /home/datasets/.ssh/pagecounts_rsync_key locke.wikimedia.org "
    echo "/a/webstats/dumps /mnt/data/pagecounts/incoming /mnt/data/xmldatadumps/public/other/pagestats-raw";
    exit 1
}

if [ $# -ne 6  ]; then
    usage
fi

username="$1"
sshkey="$2"
sourcehost="$3"
remotesrcdir="$4"
localsrcdir="$5"
webdir="$6"

retries=0
# don't run if there's a remote rsync already running, instead whine and quit
# three retries, 5 minutes between retries, it's kinda arbitrary but whatever
while [ 1 ]; do
    isrunning=$( ssh -o StrictHostKeyChecking=no -i $2 -l ${username} ${sourcehost} ps -C rsync -ww --no-headers -o args | grep ${remotesrcdir} | grep server )
    if [ ! -z "$isrunning" ]; then
    if [ $retries -gt 3 ]; then
        echo "Job failed, one or more rsyncs is already running, see:"
        echo "$isrunning"
        exit 1
    else
        sleep 300
        retries=$(( $retries+1 ))
    fi
    else
    break
    fi
done

# rsync the stuff over from host where the pagecounts are generated to local staging area

/usr/bin/rsync -a --chmod=go-w --rsh="ssh -o StrictHostKeyChecking=no -i $2" --delete ${username}@${sourcehost}:${remotesrcdir}/ ${localsrcdir}/
if [ $? -ne 0 ]; then
    echo "Rsync from remote host $sourcehost${remotesrcdir}/ to local host directory ${localsrcdir}/ failed!"
    exit 1
fi
chmod 644 ${localsrcdir}/*

# for files from each unique month and year,
# rsync those locally into web-accessible location

if [ ! -d "$localsrcdir" ]; then
  echo "Failed: source directory $localsrcdir does not exist!"
  exit 1
fi

if [ ! -d "$webdir" ]; then
    mkdir "$webdir"
    if [ $? -ne 0 ]; then
    echo "Failed to create web directory $webdir!"
    exit 1
    fi
    chmod 755 "$webdir"
fi

# get years and months of pagecount/projectcount files:
# lose every thing but the first 6 digits in the name
# filename format is pagecounts-20101101-000000.gz or projectcounts-20101120-030000
list=$( ( cd "$localsrcdir"; ls pagecounts*gz projectcounts*[0-9] 2>/dev/null | sed -r -e 's/pagecounts-//g; s/projectcounts-//g; s/[0-9]{2}-[0-9]{6}([.]gz)?$//g;') | sort | uniq )

years=$( echo "$list" | sed -r -e 's/[0-9]{2}$//g;' | sort | uniq )
for y in $years; do

    # set up yearly directory and yearly index.html if needed
    ydestdir=$webdir/$y
    if [ ! -d $ydestdir ]; then
    mkdir $ydestdir
    if [ $? -ne 0 ]; then
        echo "Failed to create destination directory per year $ydestdir!"
        exit 1
    fi
    chmod 755 $ydestdir
    cd $webdir
    /usr/local/bin/generate-pagecount-main-index.sh
    elif [ ! -f $webdir/index.html ]; then
    cd $webdir
    /usr/local/bin/generate-pagecount-main-index.sh
    fi

    # set up monthly directories for this year and monthly index.html files if needed
    thisyearmonthslist=$( echo "$list" | grep $y )

    months=$( echo "$thisyearmonthslist" | sed -r -e 's/^[0-9]{4}//g;' | sort | uniq )
    regenindex=0
    for m in $months; do
    mdestdir="$ydestdir/$y-$m"
    if [ ! -d $mdestdir ]; then
        regenindex=1
        mkdir $mdestdir
        if [ $? -ne 0 ]; then
        echo "Failed to create destination directory per month $mdestdir!"
        exit 1
        fi
        chmod 755 $mdestdir
    fi
    done

    # rsync files from staging area into the right web subdirectory for year/month
    for m in $months; do

    mdestdir="$ydestdir/$y-$m"

    therearefiles=$( ls $localsrcdir/pagecounts-$y$m*.gz 2>/dev/null )
    if [ ! -z "$therearefiles" ]; then
        newpagefiles=$( rsync -v -t $localsrcdir/pagecounts-$y$m*.gz $mdestdir )
        if [ $? -ne 0 ]; then
        echo "Rsync of pagecount files from $localsrcdir to $mdestdir failed!"
        exit 1
        fi
        newpagefiles=$( for f in $newpagefiles; do if [[ $f =~ ^pagecount ]]; then echo $f; fi done )
    else
        newpagefiles=""
    fi
    therearefiles=$( ls $localsrcdir/projectcounts-$y$m*[0-9] 2>/dev/null )
    if [ ! -z "$therearefiles" ]; then
        newprojfiles=$( rsync -v -t $localsrcdir/projectcounts-$y$m*[0-9] $mdestdir )
        if [ $? -ne 0 ]; then
        echo "Rsync of projectcount files from $localsrcdir to $mdestdir failed!"
        exit 1
        fi
        newprojfiles=$( for f in $newprojfiles; do if [[ $f =~ ^projectcount ]]; then echo $f; fi done )
    else
        newprojfiles=""
    fi

    declare -a newfilesbasenames=()
    for f in $newpagefiles; do
        newfilesbasenames+=( $( basename $f ) )
    done
    for f in $newprojfiles; do
        newfilesbasenames+=( $( basename $f ) )
    done
    SAVE_IFS=$IFS
    IFS="|"
    newfilesexpr="${newfilesbasenames[*]}"
    IFS=$SAVE_IFS

    # do md5s only for the files needed
    # (generating md5 sums for all files is too slow every hour, we're talking
    # about 60gb of files when we get to the end of the month

    # get list of files we have current md5s for
    # if we just updated a file its md5 is outdated
    cd $mdestdir
    md5tempfile=$( mktemp $mdestdir/md5temp.XXXX )
    if [ $? -ne 0 ]; then
        echo "Failed to create temp file for md5 hashes!"
        exit 1
    fi
    if [ -e md5sums.txt ]; then
        if [ ! -z "$newfilesexpr" ]; then
        cat md5sums.txt | egrep -v "($newfilesexpr)" > $md5tempfile
        else
        cat md5sums.txt > $md5tempfile
        fi
    else
        > $md5tempfile
    fi
    havemd5s=( $( cat $md5tempfile | awk '{ print $2 }' ) )

    # get the total list of page/projectcount files
    havefiles=( $( ls pagecounts-$y$m*.gz projectcounts-$y$m*[0-9] 2>/dev/null ) )

    # get the page/projectcount files for which there are no md5s
    nomd5s=()
    for f in "${havefiles[@]}"; do
        found=0
        for h in "${havemd5s[@]}"; do
        if [ $f == $h ]; then
            found=1; break;
        fi
        done
        if [ $found -eq 0 ]; then
        nomd5s+=( "$f" )
        fi
    done

    # get md5s for the files needed
    if [ ${#nomd5s[@]} -ne 0 ]; then
#        echo "doing md5s of" ${nomd5s[@]}
        md5sum ${nomd5s[@]} >> $md5tempfile
    fi

    sort -k 2,2 $md5tempfile > ${md5tempfile}.sorted
    mv ${md5tempfile}.sorted md5sums.txt
    chmod 644 md5sums.txt
    rm $md5tempfile
    /usr/local/bin/generate-pagecount-year-month-index.sh

    done

    if [ $regenindex -ne 0 ]; then
    cd $ydestdir
    /usr/local/bin/generate-pagecount-year-index.sh
    elif [ ! -f $ydestdir/index.html ]; then
    cd $ydestdir
    /usr/local/bin/generate-pagecount-year-index.sh
    fi

done
