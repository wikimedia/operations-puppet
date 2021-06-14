#!/bin/bash
set -euf -o pipefail
PATH=/usr/bin
EXIT=0
for staged in $(git diff-index --cached --name-only --diff-filter=AM HEAD)
do
  # Only check yaml files in the hieradata directory
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
exit $EXIT
