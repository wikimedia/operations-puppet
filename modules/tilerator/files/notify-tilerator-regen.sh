#!/bin/bash

osmosis_dir=$1
from_zoom=$2
before_zoom=$3
generator_id=$4
storage_id=$5
delete_empty=$6
expire_dir=$7
statefile=$8

if [ "$delete_empty" = false ]; then
    delete_empty=""
fi

/usr/bin/flock -xn "${osmosis_dir}/replicate-osm.lck" \
    /usr/bin/nodejs /srv/deployment/tilerator/deploy/node_modules/tilerator/scripts/tileshell.js \
        --config config.dev.yaml \
        -j.fromZoom $from_zoom \
        -j.beforeZoom $before_zoom \
        -j.generatorId $generator_id \
        -j.storageId $storage_id \
        ${delete_empty:+ -j.deleteEmpty} \
        -j.expdirpath $expire_dir \
        -j.expmask 'expire\.list\.*' \
        -j.statefile $statefile

notification_code=$?

if [ $notification_code -ne 0 ] ; then
    echo "$(date '+%m/%d/%Y %H:%M:%S') - Error while notifying tileratorui"
    exit $notification_code
else
    echo "$(date '+%m/%d/%Y %H:%M:%S') - Tileratorui notified with success"
fi
