#!/bin/bash

osmosis_dir=$1
zoom=$2
from_zoom=$3
before_zoom=$4
generator_id=$5
storage_id=$6
delete_empty=$7

if [ "$delete_empty" = false ]; then
    delete_empty=""
fi

/usr/bin/flock -xn "${osmosis_dir}/replicate-osm.lck" \
    /usr/bin/nodejs /srv/deployment/tilerator/deploy/node_modules/@kartotherian/tilerator/scripts/tileshell.js \
        --config /etc/tileratorui/config.yaml \
        -j.zoom $zoom \
        -j.fromZoom $from_zoom \
        -j.beforeZoom $before_zoom \
        -j.generatorId $generator_id \
        -j.storageId $storage_id \
        ${delete_empty:+ -j.deleteEmpty}

notification_code=$?

if [ $notification_code -ne 0 ] ; then
    echo "$(date '+%m/%d/%Y %H:%M:%S') - Error while notifying tileratorui"
    exit $notification_code
else
    echo "$(date '+%m/%d/%Y %H:%M:%S') - Tileratorui notified with success"
fi
