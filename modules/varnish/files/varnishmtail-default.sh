#!/bin/bash
#
# varnishmtail-default - Default varnishmtail instance responsible for most
#                        mtail scripts. The other one is varnishmtail-internal.

# Treat unset variables as an error when substituting
set -u

PROGS=${1?missing mtail programs directory}
PORT=${2?missing mtail port number}

fmt_side='side %{Varnish:side}x'
fmt_url='url %U'
fmt_cache_status='cache_status %{X-Cache-Status}o'
fmt_http_status='http_status %s'
fmt_http_method='http_method %m'
fmt_cache_control='cache_control %{Cache-Control}o'
fmt_inm='inm %{If-None-Match}i'
fmt_ttfb='ttfb %{Varnish:time_firstbyte}x'
fmt_cache_int='cache_int %{X-Cache-Int}o'

FMT="${fmt_side}\t${fmt_url}\t${fmt_cache_status}\t${fmt_http_status}\t${fmt_http_method}\t${fmt_cache_control}\t${fmt_inm}\t${fmt_ttfb}\t${fmt_cache_int}\t"

/usr/local/bin/varnishmtail-wrapper "${PROGS}" "${PORT}" varnishmtail-default "${FMT}"
