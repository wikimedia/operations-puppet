#!/bin/bash
#
# varnishmtail - pipe varnishncsa frontend output to mtail

[ -r /etc/default/varnishmtail ] && . /etc/default/varnishmtail
PROGS="${1:-/etc/mtail}"

fmt_side='side %{Varnish:side}x'
fmt_url='url %U'
fmt_cache_status='cache_status %{X-Cache-Status}o'
fmt_http_status='http_status %s'
fmt_http_method='http_method %m'
fmt_cache_control='cache_control %{Cache-Control}o'
fmt_inm='inm %{If-None-Match}i'
fmt_ttfb='ttfb %{Varnish:time_firstbyte}x'
fmt_cache_int='cache_int %{X-Cache-Int}o'
fmt_error='error %{VSL:Error}x'
fmt_fetch_error='fetcherror %{VSL:FetchError}x'

# Request handling timestamps
fmt_timestamp_start='tstart %{VSL:Timestamp:Start[3]}x'
fmt_timestamp_req='treq %{VSL:Timestamp:Req[3]}x'
fmt_timestamp_reqbody='treqbody %{VSL:Timestamp:ReqBody[3]}x'
fmt_timestamp_waitinglist='twaitinglist %{VSL:Timestamp:WaitingList[3]}x'
fmt_timestamp_fetch='tfetch %{VSL:Timestamp:Fetch[3]}x'
fmt_timestamp_process='tprocess %{VSL:Timestamp:Process[3]}x'
fmt_timestamp_resp='tresp %{VSL:Timestamp:Resp[3]}x'
fmt_timestamp_restart='trestart %{VSL:Timestamp:Restart[3]}x'

# Pipe handling timestamps
fmt_timestamp_pipe='tpipe %{VSL:Timestamp:Pipe[3]}x'
fmt_timestamp_pipesess='tpipesess %{VSL:Timestamp:PipeSess[3]}x'

# Backend fetch timestamps
fmt_timestamp_bereq='tbereq %{VSL:Timestamp:Bereq[3]}x'
fmt_timestamp_beresp='tberesp %{VSL:Timestamp:Beresp[3]}x'
fmt_timestamp_berespbody='tberespbody %{VSL:Timestamp:BerespBody[3]}x'
fmt_timestamp_retry='tretry %{VSL:Timestamp:Retry[3]}x'
fmt_timestamp_error='terror %{VSL:Timestamp:Error[3]}x'

FMT="${fmt_side}\t${fmt_url}\t${fmt_cache_status}\t${fmt_http_status}\t${fmt_http_method}\t${fmt_cache_control}\t${fmt_inm}\t${fmt_ttfb}\t${fmt_cache_int}\t${fmt_error}\t${fmt_fetch_error}\t${fmt_timestamp_start}\t${fmt_timestamp_req}\t${fmt_timestamp_reqbody}\t${fmt_timestamp_waitinglist}\t${fmt_timestamp_fetch}\t${fmt_timestamp_process}\t${fmt_timestamp_resp}\t${fmt_timestamp_restart}\t${fmt_timestamp_pipe}\t${fmt_timestamp_pipesess}\t${fmt_timestamp_bereq}\t${fmt_timestamp_beresp}\t${fmt_timestamp_berespbody}\t${fmt_timestamp_retry}\t${fmt_timestamp_error}\t"

# Pass -c and -b to log requests from clients (tls terminators) and to backends (origin)
/usr/bin/varnishncsa -P /run/varnishncsa-mtail.pid -n frontend -c -b -F "${FMT}" | mtail -progs "${PROGS}" -logs /dev/stdin -disable_fsnotify $MTAIL_ARGS &

while :; do
    sleep 1

    if ! kill -0 "$(cat /run/varnishncsa-mtail.pid)" 2> /dev/null ; then
        echo "varnishncsa seems to have crashed, exiting" >&2
        exit 1
    fi
done
