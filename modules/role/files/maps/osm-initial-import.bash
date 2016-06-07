#!/usr/bin/env bash

download_dir="/srv/downloads/initial-download/"
osmosis_dir="/srv/osmosis"
kartotherian_dir="/srv/deployment/kartotherian/deploy/"
osm_bright_source_dir="${kartotherian_dir}/node_modules/osm-bright-source"
proxy=
database_host=`hostname -f`
log_file=/var/log/osm-initial-import.log

while getopts "dhHpx" opt; do
  case "${opt}" in
  d)  dump_date="${OPTARG}"
      ;;
  h)  show_help
      exit 0
      ;;
  H)  database_host="${OPTARG}"
      ;;
  x)  password_file="${OPTARG}"
      ;;
  x)  proxy="-x ${OPTARG}"
      ;;
  esac
done

function show_help() {
  echo "osm-initial-import.bash -d <date_of_import> [-H <database_host>] -p <password_file> -x <proxy>"
  echo "  date_of_import: find the latest dump at http://planet.osm.org/pbf/"
  echo "  database_host: hostname of the postgresql database, default to `hostname -f`"
  echo "  password_file: a file containing the postgresql password of the osmimporter user"
  echo "  proxy: proxy used to download PBF files"
  echo ""
  echo "WARNING: the import is going to run for a long, long time. You should probably run this from inside screen or similar"
  echo ""
  echo "  example: osm-initial-import.bash -d 160530 -p ~/osmimporter_pass -x webproxy.eqiad.wmnet:8080"
}

function download_pbf() {
  cd ${download_dir}
  curl ${proxy} -C - -O http://planet.osm.org/pbf/planet-${dump_date}.osm.pbf.md5
  curl ${proxy} -C - -O http://planet.osm.org/pbf/planet-${dump_date}.osm.pbf
  md5sum -c planet-${dump_date}.osm.pbf.md5
  if [ $? -ne 0 ] ; then
    echo "Download of PBF file failed, md5sum is invalid"
    exit -1
  fi
}

function reset_postgres() {
  puppet agent --disable "database reload in progress"
  service postgresql@9.4-main stop

  rm -rf /srv/postgresql/9.4/main

  mkdir /srv/postgresql/9.4/main
  chown postgres: /srv/postgresql/9.4/main/
  chmod 700 /srv/postgresql/9.4/main/

  sudo -u postgres /usr/lib/postgresql/9.4/bin/initdb -D /srv/postgresql/9.4/main
  service postgresql@9.4-main start

  # puppet creates multiple postgis resources
  puppet agent --enable
  puppet agent -t
  cat /usr/local/bin/maps-grants.sql | sudo -u postgres psql -d gis -f -
}

function initial_osm_import() {
  # disable replicate-osm cronjob
  puppet apply -e "cron { 'planet_sync-gis': ensure => absent, user => 'osmupdater' }"

  puppet agent --disable "database reload in progress"
  service tilerator stop
  service tileratorui stop


  cd ${osmosis_dir}
  PGPASSWORD="$(< ${password_file})" sudo -E -u osmupdater osm2pgsql \
    --create --slim --flat-nodes nodes.bin -C 40000 --number-processes 8 \
    --hstore --host ${database_host} -U osmimporter -d gis \
    ${download_dir}/planet-${dump_date}.osm.pbf 2>&1 | tee ${log_file}

  if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo "osm2pgsql failed to complete initial import"
    exit -1
  fi
  puppet agent --enable
  puppet agent -t
}

function import_water_polygons() {
  cd ${download_dir}

  curl ${proxy} -C - -O http://data.openstreetmapdata.com/water-polygons-split-3857.zip
  unzip water-polygons-split-3857.zip

  cd water-polygons-split-3857
  shp2pgsql -I -s 3857 -g way water_polygons.shp water_polygons | sudo -u postgres psql -Xqd gis
}

function custom_functions_and_indexes() {
  sudo -u postgres psql -Xd gis -f "${osm_bright_source_dir}/node_modules/postgis-vt-util/lib.sql"
  sudo -u postgres psql -Xd gis -f "${osm_bright_source_dir}/sql/admin.sql"
  sudo -u postgres psql -Xd gis -f "${osm_bright_source_dir}/sql/functions.sql"
  sudo -u postgres psql -Xd gis -f "${osm_bright_source_dir}/sql/water-indexes.sql"
  sudo -u postgres psql -d gis -c 'select populate_admin();'
}
function cleanup() {
  rm "${download_dir}/planet-${dump_date}.osm.pbf.md5"
  rm "${download_dir}/planet-${dump_date}.osm.pbf"
  rm "${download_dir}/water-polygons-split-3857.zip"
}

download_pbf
reset_postgres
initial_osm_import
import_water_polygons
custom_functions_and_indexes
cleanup