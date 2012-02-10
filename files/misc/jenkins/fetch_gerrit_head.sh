#!/bin/bash
# THIS FILE IS MANAGED BY PUPPET
# puppet:///files/misc/jenkins/fetch_gerrit_head.sh
#
# Script extracted from the OpenStack project v2012.02.08
#   http://ci.openstack.org/gerrit.html
#
# This script should be run before a build so we apply the a gerrit change
# against lastest HEAD, not against whatever HEAD was when change was sent.
#

set -x

if [ -z "$WORKSPACE" ] || [ -z "$GERRIT_BRANCH" ]; then
	echo "\$WORKSPACE and \$GERRIT_BRANCH must be set."
	exit 1
fi

cd $WORKSPACE || exit 1

git checkout $GERRIT_BRANCH
git reset --hard remotes/origin/$GERRIT_BRANCH
git merge FETCH_HEAD
CODE=$?

if [ ${CODE} -ne 0 ]; then
	git reset --hard remotes/origin/$GERRIT_BRANCH
	exit ${CODE}
fi
