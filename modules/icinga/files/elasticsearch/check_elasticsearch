#!/bin/sh

# Note: This file is managed by Puppet.

#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

PROGNAME=`basename $0`
VERSION="Version 0.2.0,"
AUTHOR="Andrew Lyon, Based on Mike Adolphs (http://www.matejunkie.com/) check_nginx.sh code"


ST_OK=0
ST_WR=1
ST_CR=2
ST_UK=3
hostname="localhost"
port=9200
status_page="/_cluster/health"
output_dir=/tmp
secure=0

print_version() {
    echo "$VERSION $AUTHOR"
}

print_help() {
    print_version $PROGNAME $VERSION
    echo ""
    echo "$PROGNAME is a Nagios plugin to check the cluster status of elasticsearch."
	echo "It also parses the status page to get a few useful variables out, and return"
	echo "them in the output."
    echo ""
    echo "$PROGNAME -H localhost -P 9200 -o /tmp"
    echo ""
    echo "Options:"
    echo "  -H/--hostname)"
    echo "     Defines the hostname. Default is: localhost"
    echo "  -P/--port)"
    echo "     Defines the port. Default is: 9200"
    echo "  -o/--output-directory)"
    echo "     Specifies where to write the tmp-file that the check creates."
    echo "     Default is: /tmp"
    exit $ST_UK
}

while test -n "$1"; do
    case "$1" in
        -help|-h)
            print_help
            exit $ST_UK
            ;;
        --version|-v)
            print_version $PROGNAME $VERSION
            exit $ST_UK
            ;;
        --hostname|-H)
            hostname=$2
            shift
            ;;
        --port|-P)
            port=$2
            shift
            ;;
        --output-directory|-o)
            output_dir=$2
            shift
            ;;
        *)
            echo "Unknown argument: $1"
            print_help
            exit $ST_UK
            ;;
    esac
    shift
done

get_status() {
    filename=${PROGNAME}-${hostname}-${status_page}.1
    filename=`echo $filename | tr -d '\/'`
    filename=${output_dir}/${filename}
	wget -q --header Host:stats -t 3 -T 3 http://${hostname}:${port}/${status_page}?pretty=true -O ${filename}
}

get_vals() {
	name=`grep cluster_name ${filename} | awk '{print $3}' | sed 's|[",]||g'`
	status=`grep status ${filename} | awk '{print $3}' | sed 's|[",]||g'`
	timed_out=`grep timed_out ${filename} | awk '{print $3}' | sed 's|[",]||g'`
	number_nodes=`grep number_of_nodes ${filename} | awk '{print $3}' | sed 's|[",]||g'`
	number_data_nodes=`grep number_of_data_nodes ${filename} | awk '{print $3}' | sed 's|[",]||g'`
	active_primary_shards=`grep active_primary_shards ${filename} | awk '{print $3}' | sed 's|[",]||g'`
	active_shards=`grep active_shards ${filename} | awk '{print $3}' | sed 's|[",]||g'`
	relocating_shards=`grep relocating_shards ${filename} | awk '{print $3}' | sed 's|[",]||g'`
	initializing_shards=`grep initializing_shards ${filename} | awk '{print $3}' | sed 's|[",]||g'`
	unassigned_shards=`grep unassigned_shards ${filename} | awk '{print $3}' | sed 's|[",]||g'`
	rm -f ${filename}
}

do_output() {
    output="elasticsearch ($name) is running. \
status: $status; \
timed_out: $timed_out; \
number_of_nodes: $number_nodes; \
number_of_data_nodes: $number_data_nodes; \
active_primary_shards: $active_primary_shards; \
active_shards: $active_shards; \
relocating_shards: $relocating_shards; \
initializing_shards: $initializing_shards; \
unassigned_shards: $unassigned_shards "
}

do_perfdata() {
    #perfdata="'idle'=$iproc 'active'=$aproc 'total'=$tproc"
    perfdata="'active_primary'=$active_primary_shards 'active'=$active_shards 'relocating'=$relocating_shards 'init'=$initializing_shards"
}

# Here we go!
get_status
if [ ! -s "$filename" ]; then
        echo "CRITICAL - Could not connect to server $hostname"
        exit $ST_CR
else
        get_vals
        if [ -z "$name" ]; then
                echo "CRITICAL - Error parsing server output"
                exit $ST_CR
        else
                do_output
                do_perfdata
        fi
fi

COMPARE=$listql

if [ "$status" = "red" ]; then
	echo -n "CRITICAL"
	EXST=$ST_CR
elif [ "$status" = "yellow" ]; then
	echo -n "WARNING"
	EXST=$ST_WR
elif [ "$status" = "green" ]; then
	echo -n "OK"
	EXST=$ST_OK
else
	echo -n "UNKNOWN"
	EXST=$ST_UK
fi

echo " - ${output} | ${perfdata}"
exit $EXST