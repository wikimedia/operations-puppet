#!/bin/bash

# Basic setup for the puppet git repository

# Need this info
echo "Type your Labs console wiki username (ie: Test User):"
read name
echo "Type your shell username (ie: testuser):"
read username
echo "Type the e-mail address for this username:"
read email

# Global config
git config --global user.email "$email"
git config --global user.name "$name"

# Setup remotes/aliases
git remote add puppet ssh://$username@gerrit.wikimedia.org:29418/operations/puppet
git config alias.push-for-review-test "push puppet HEAD:refs/for/test"
git config alias.push-for-review-production "push puppet HEAD:refs/for/production"

TOPLEVEL=`git rev-parse --show-toplevel`
which curl
if [ "$?" == "0" ]
then
	curl "https://gerrit.wikimedia.org/r/tools/hooks/commit-msg" > $TOPLEVEL/.git/hooks/commit-msg && chmod u+x $TOPLEVEL/.git/hooks/commit-msg
else
	which wget
	if [ "$?" == "0" ]
	then
		wget "https://gerrit.wikimedia.org/r/tools/hooks/commit-msg" -O $TOPLEVEL/.git/hooks/commit-msg && chmod u+x $TOPLEVEL/.git/hooks/commit-msg
	else
		scp -p 29418 gerrit.wikimedia.org:hooks/commit-msg $TOPLEVEL/.git/hooks/commit-msg
		if [ "$?" != "0" ]
		then
			echo "Please download the commit message hook from https://gerrit.wikimedia.org/r/tools/hooks/commit-msg, place it in .git/hooks/commit-msg, and chmod u+x the file."
		fi
	fi
fi
