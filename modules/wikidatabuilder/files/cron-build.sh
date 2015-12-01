#!/usr/bin/env bash
# License AGPL version 3 or later
# Authors: Addshore, JanZerebecki
set -ex

export PATH="/data/wdbuilder/composer/vendor/bin/:/usr/local/bin:/usr/bin:/bin:"

# Get the date at the start of the script for use in the commit msg
now="$(date -Is)"

echo --1-- Rebuilding Wikidata Build

# Make sure the WikidataBuilder is up to date
cd /data/wdbuilder/buildresources
git checkout master
git fetch origin master
git reset --hard origin/master
# Rebuild Wikidata
./node_modules/.bin/grunt install

# Only continue if the build returned "0" success
build_exit_value=$?
if [ "${build_exit_value}" -eq "0" ] ; then

	echo --2-- Pulling current Wikidata Repo

	# Checkout the current master of Wikidata!
	# If we dont do this our .git will be wrong and things get messy
	cd /data/wdbuilder/wikidata
	git checkout master
	git fetch origin master
	git reset --hard origin/master

	echo --3-- Copying the new Wikidata build to the Repo

	# Make a temporary folder for our new build
	mkdir /data/wdbuilder/wikidata-tmp
	# Copy the .git from the Wikidata repo over to our tmp folder
	cp --recursive --no-dereference --preserve=mode,links /data/wdbuilder/wikidata/.git /data/wdbuilder/wikidata-tmp/
	# Force remove everything from the git index
	cd /data/wdbuilder/wikidata-tmp
	git rm --quiet -rf *
	# Copy all files created from the build into our new folder
	cd /data/wdbuilder/buildresources
	GLOBIGNORE=.:..:.git
	cp -r * .* /data/wdbuilder/wikidata-tmp/
	unset GLOBIGNORE
	# Remove the old Wikidata folder and copy our new one over
	rm -rf /data/wdbuilder/wikidata
	mv /data/wdbuilder/wikidata-tmp /data/wdbuilder/wikidata

	echo --4-- Committing new Wikidata build

	# Add all files to the commit and commit to gerrit!
	cd /data/wdbuilder/wikidata
	# remove .git directories so as not to use submodules instead of a deep copy
	find -mindepth 2 -iname '.git' -exec 'rm' '-rf' '{}' '+'
	git add .
	git add --force composer.lock
	git commit -m "New Wikidata Build - $now"
	git push origin HEAD:refs/publish/master
	git reset --hard origin/master

else

	# TODO retry after a certain ammount of time?
	echo "Build exited with a bad error code...."

fi
