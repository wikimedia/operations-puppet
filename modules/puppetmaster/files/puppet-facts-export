#!/bin/bash

set -e
set -u

if [ `whoami` != "root" ]; then
    echo "Needs to be run as root"
    exit
fi

tmpdir=$(mktemp -d)
mkdir -p $tmpdir/yaml/facts
outfile=/tmp/puppet-facts-export.tar.xz
factsdir=/var/lib/puppet/yaml/facts

function cleanup() {
    rm -rf "$tmpdir"
}

trap cleanup EXIT

rsync -a0 \
    --files-from=<(find $factsdir -type f -mtime -7 -printf "%f\0") $factsdir \
    "$tmpdir/yaml/facts"
chown -R "${USER}" "$tmpdir/yaml"

for FILE in "${factsdir}"/*.yaml; do
    TIME=$(stat -c "%y" "${FILE}")
    sed -i -e 's@uniqueid:.*@uniqueid: "43434343"@' \
        -e 's@boardserialnumber:.*@boardserialnumber: "4242"@' \
        -e 's@boardproductname:.*@boardproductname: "424242"@' \
        -e 's@serialnumber:.*@serialnumber: "42424242"@' \
        -e '/^ *trusted\:/ d' "${FILE}"
    touch -d "${TIME}" "${FILE}"
done

tar cJvf $outfile --directory "$tmpdir" yaml

echo "puppet facts sanitized and exported at $outfile"
