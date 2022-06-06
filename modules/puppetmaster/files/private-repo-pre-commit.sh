#!/bin/bash
set -euf -o pipefail
PATH=/usr/bin
EXIT=0
CHECK_REQUESTCTL=0
for staged in $(git diff-index --cached --name-only --diff-filter=AM HEAD)
do
  # Only check yaml files in the hieradata directory
  if [ "${staged%%/*}" == "requestctl" ]
  then
    CHECK_REQUESTCTL=1
  fi
  if [ "${staged%%/*}" != "hieradata" ]
  then
    continue
  fi
  # Ensure all files in hieradata have a yaml extension
  if [ "${staged##*\.}" != "yaml" ]
  then
    printf "File has invalid extension: %s\\n" "${staged}"
    EXIT=1
    continue
  fi
  printf "Checking: %s\\n" "$staged"
  # use git show to ensure we check the staged file instead of the on disk file
  git show :"${staged}" | yamllint -c /etc/puppet/yamllint.yaml - || EXIT=1
done
if [ ${CHECK_REQUESTCTL} -eq 1 ]
then
  # TODO: with this we check the files on disk and not the ones staged which could in theory be different
  # however i believe requestctl always uses the files on disk so this is probably the right thing to do?
  requestctl validate /srv/private/requestctl || EXIT=1
fi
exit $EXIT
