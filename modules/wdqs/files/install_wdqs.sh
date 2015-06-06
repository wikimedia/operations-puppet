#!/bin/bash
# This script downloads and unpacks WDQS distribution package using maven
VERSION=$1
PACKAGE_DIR=$2

TMP=`mktemp -d --tmpdir=$PACKAGE_DIR`

/usr/bin/mvn org.apache.maven.plugins:maven-dependency-plugin:2.10:unpack -Dartifact=org.wikidata.query.rdf:service:$VERSION:zip:dist -DoutputDirectory=$PACKAGE_DIR -Dtransitive=false -Dproject.basedir=$TMP
rm -rf $TMP
