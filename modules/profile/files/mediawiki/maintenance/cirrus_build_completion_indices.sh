#!/usr/bin/env bash

## Input: $1 is cluster to update (either eqiad or codfw)

/usr/local/bin/expanddblist all | xargs -I{} -P 4 sh -c "/usr/local/bin/mwscript extensions/CirrusSearch/maintenance/UpdateSuggesterIndex.php --wiki={} --masterTimeout=10m --replicationTimeout=5400 --indexChunkSize 3000 --cluster=$1 --optimize 2>&1 | ts '{}'"
