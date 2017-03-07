#!/usr/bin/env bash

# This script will
# 1. Download OSM data and load it into a DB
# 2. Update that DB
# 3. Keep a local copy of the planet up to date

# Requirements
# - osmium-tool
# - osmosis
# - osm2pgsql
# - ClearTables
# - meddo

set -e

BASE_DIR="/srv/osm_replication"
CLEARTABLES="TBD"
MEDDO="/usr/share/meddo"

DATABASE="ct"

PLANET_DIR="$BASE_DIR/planet"
PLANET_REPLICATION_BASE="$PLANET_DIR/planet-replication"
DATABASE_REPLICATION_BASE="$PLANET_DIR/database-replication"

# -E 3857 is not required on newer versions of osm2pgsql
osm2pgsql_common_opts="-E 3857  --flat-nodes $PLANET_DIR/nodes.bin"
osm2pgsql_import_opts="--cache 10000 --number-processes 2"
osm2pgsql_update_opts="--cache 1000 --number-processes 1"

function show_setup_help() {
  cat << EOF
Usage: ${0##*/} setup data_url state_url replication_url

Examples:
  ${0##*/} setup http://download.geofabrik.de/north-america/canada/british-columbia-170101.osm.pbf \\
    http://download.geofabrik.de/north-america/canada/british-columbia-updates/000/001/384.state.txt \\
    http://download.geofabrik.de/north-america/canada/british-columbia-updates

EOF
exit 1
}

function setup_data() {
  if [ -z "$1" ]; then
    echo "data_url not set"
    show_setup_help
    exit 0
  fi
  if [ -z "$2" ]; then
    echo "state_url not set"
    show_setup_help
    exit 0
  fi
  if [ -z "$3" ]; then
    echo "replication_url not set"
    show_setup_help
    exit 0
  fi
  PLANET_URL="$1"
  STATE_URL="$2"
  REPLICATION_BASE="$3"

  mkdir -p "$PLANET_DIR"
  mkdir -p "$PLANET_REPLICATION_BASE"

  cat <<EOF > "$PLANET_REPLICATION_BASE/configuration.txt"
# The URL of the directory containing change files.
baseUrl=$REPLICATION_BASE

# Allow 3 days of downloads
maxInterval = 259200
EOF

  echo "Downloading files"
  curl --retry 5 -o "$PLANET_DIR/osm-data.osm.pbf" "$PLANET_URL"
  curl --retry 5 -o "$PLANET_REPLICATION_BASE/state.txt" "$STATE_URL"

  # Call a function here to update the planet later
}

function onplanetupdateexit {
    [ -f "$PLANET_REPLICATION_BASE/state-prev.txt" ] && mv "$PLANET_REPLICATION_BASE/state-prev.txt" "$PLANET_REPLICATION_BASE/state.txt"
}

function load_borders() {
  echo "Loading borders"
  psql -d ct -v ON_ERROR_STOP=1 -Xq <<EOF
CREATE SCHEMA IF NOT EXISTS loading;
DROP TABLE IF EXISTS loading.osmborder_lines;
CREATE TABLE loading.osmborder_lines (
  osm_id bigint,
  admin_level int,
  dividing_line bool,
  disputed bool,
  maritime bool,
  way Geometry(LineString, 3857));
\copy loading.osmborder_lines FROM $PLANET_DIR/osmborder_lines.csv
CREATE INDEX osmborder_lines_way_idx ON loading.osmborder_lines USING gist (way) WITH (fillfactor=100);
CLUSTER loading.osmborder_lines USING osmborder_lines_way_idx;
CREATE INDEX osmborder_lines_way_low_idx ON loading.osmborder_lines USING gist (way) WITH (fillfactor=100) WHERE admin_level <= 4;
ANALYZE loading.osmborder_lines;
BEGIN;
DROP TABLE IF EXISTS public.osmborder_lines;
ALTER TABLE loading.osmborder_lines SET SCHEMA public;
COMMIT;
EOF
}

function planet_update() {
  pushd "$PLANET_REPLICATION_BASE"
  trap onplanetupdateexit EXIT
  set -e
  cp state.txt state-prev.txt
  # Clean up from any previous runs
  rm -f "$PLANET_DIR/changes.osc"
  osmosis --read-replication-interval --write-xml-change file="$PLANET_DIR/changes.osc"
  osmium apply-changes -v --fsync "$PLANET_DIR/osm-data.osm.pbf" "$PLANET_DIR/changes.osc" -o "$PLANET_DIR/osm-data-new.osm.pbf"
  mv "$PLANET_DIR/osm-data-new.osm.pbf" "$PLANET_DIR/osm-data.osm.pbf"
  # File is updated, clean up derived files
  rm -f "$PLANET_DIR/changes.osc" "$PLANET_DIR/osm-filtered.osm.pbf" "$PLANET_DIR/osmborder_lines.csv"
  osmborder_filter -o "$PLANET_DIR/osm-filtered.osm.pbf" "$PLANET_DIR/osm-data.osm.pbf"
  osmborder -o "$PLANET_DIR/osmborder_lines.csv" "$PLANET_DIR/osm-filtered.osm.pbf"
  load_borders
  rm state-prev.txt
}

function create_database() {
  createdb $DATABASE
  psql -1Xq -d $DATABASE -c 'CREATE EXTENSION postgis; CREATE EXTENSION hstore;'
  # Meddo needs these extensions above and beyond what ClearTables needs
  psql -1Xq -d $DATABASE -c 'CREATE EXTENSION unaccent; CREATE EXTENSION fuzzystrmatch;'
  psql -d $DATABASE -f "$MEDDO/functions.sql"
}

function import_data() {
  # TODO: creating data base is done by puppet, we should remove it from this
  # script or hide it behind a flag
  create_database

  # Snapshot the current state
  cp -r "$PLANET_REPLICATION_BASE" "$DATABASE_REPLICATION_BASE"

  # https://github.com/openstreetmap/osm2pgsql/issues/321 requires switching directories
  pushd "$CLEARTABLES"

  # Build the ClearTables files
  cat cleartables.yaml wikidata.yaml | ./yaml2json.py > cleartables.json
  cat cleartables.yaml wikidata.yaml | ./createcomments.py > sql/post/comments.sql

  cat sql/types/*.sql | psql -1Xq -d $DATABASE

  osm2pgsql $osm2pgsql_common_opts $osm2pgsql_import_opts --create --slim \
    -d $DATABASE --output multi --style cleartables.json \
    -G "$PLANET_DIR/osm-data.osm.pbf"
  cat sql/post/*.sql | psql -1Xq -d $DATABASE
  popd
}

function static_update() {
  # Quite a simple function thanks to Meddo's scripts
  pushd "$MEDDO"
  "$MEDDO/get-external-data.py"
  popd
}
function onupdateexit {
    [ -f "$DATABASE_REPLICATION_BASE/state-prev.txt" ] && mv "$DATABASE_REPLICATION_BASE/state-prev.txt" "$DATABASE_REPLICATION_BASE/state.txt"
}

function database_update() {
# see https://github.com/openstreetmap/chef/blob/master/cookbooks/tile/templates/default/replicate.erb for another example
# The OSMF example is a daemon with a while true loop, this is a one-shot script, but they both do the same task
  pushd "$DATABASE_REPLICATION_BASE"

  trap onupdateexit EXIT
  . state.txt
  cp state.txt state-prev.txt
  file="$PWD/changes-${sequenceNumber}.osm.gz"
  osmosis --read-replication-interval --write-xml-change file="${file}" compressionMethod="gzip"

  prevSequenceNumber=$sequenceNumber
  . state.txt
  if [ "${sequenceNumber}" == "${prevSequenceNumber}" ]
  then
    echo "No new data available. Sleeping..."
    #  Remove file, it will just be an empty changeset
    rm ${file}
    # No need to rollback now
    rm state-prev.txt
    exit 0
  else
    echo "Fetched new data from ${prevSequenceNumber} to ${sequenceNumber} into ${file}"

    # https://github.com/openstreetmap/osm2pgsql/issues/321 requires switching directories
    pushd "$CLEARTABLES"
    make
    osm2pgsql $osm2pgsql_common_opts $osm2pgsql_update_opts --append --slim \
      -d $DATABASE --output multi --style cleartables.json \
      -G ${file}

    # Something should be done to create expire lists and process them
    popd

    rm state-prev.txt

    # expire tiles

    find . -name 'changes-*.gz' -mmin +300 -exec rm -f {} \;
  fi
  popd
}


function clean () {
  if [ "$really" != "yes" ]; then
    echo "This will delete downloaded files and drop the database. If you really want to do this, set the enviornment variable \"really\" to yes"
    exit 1
  fi

  rm -rf "$PLANET_DIR"
  dropdb $DATABASE
}

function show_help() {
  cat << EOF
Usage: ${0##*/} mode

Modes:
  setup: Downloads initial data, updates it, and sets up replication (see setup --help for more info)
  import: Import the data with osm2pgsql
  static-update: Update the static data tables
  planet-update: Update the planet file and regenerate borders
  database-update: Update the database
  clean: Clean everything up

EOF
}

if [ "$#" == "0" ]; then
  show_help
  exit 1
fi

command="$1"

case "$command" in
    setup)
    shift
    setup_data $@
    ;;

    import)
    shift
    import_data
    ;;

    static-update)
    shift
    static_update
    ;;

    planet-update)
    shift
    planet_update
    ;;

    database-update)
    shift
    database_update
    ;;

    clean)
    shift
    clean
    ;;

    *)
    show_help
    ;;
esac