#! /bin/bash

#
# This script is managed by puppet
#

cd /data/project/.system/deb
for arch in *; do
  if [ -d $arch ]; then
    dpkg-scanpackages $arch | gzip -9c >$arch/Packages.gz~
    mv $arch/Packages.gz~ $arch/Packages.gz
  fi
done

