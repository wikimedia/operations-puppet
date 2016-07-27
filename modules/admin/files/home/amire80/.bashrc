# https://phabricator.wikimedia.org/T141255

lookupdbhost() {
    lookupdb=$1
    hostcode="echo \$lb->getServerName(\$lb->getReaderIndex());"
    lbcode="\$lb = wfGetLB();"
    host=`echo $lbcode $hostcode | /usr/local/bin/mwscript eval.php --wiki="$lookupdb"`
    echo $host
}

alias sqlhost=lookupdbhost

