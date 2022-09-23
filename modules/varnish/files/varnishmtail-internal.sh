#!/bin/bash
#
# varnishmtail-internal - varnishmtail instance responsible for:
#
# - varnisherrors.mtail
# - varnishsli.mtail
# - varnishprocessing.mtail

# Treat unset variables as an error when substituting
set -u

PROGS=${1?missing mtail programs directory}
PORT=${2?missing mtail port number}

# Varnish side
fmt_side='side %{Varnish:side}x'

# Error messages
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

FMT="${fmt_side}\t${fmt_error}\t${fmt_fetch_error}\t${fmt_timestamp_start}\t${fmt_timestamp_req}\t${fmt_timestamp_reqbody}\t${fmt_timestamp_waitinglist}\t${fmt_timestamp_fetch}\t${fmt_timestamp_process}\t${fmt_timestamp_resp}\t${fmt_timestamp_restart}\t${fmt_timestamp_pipe}\t${fmt_timestamp_pipesess}\t${fmt_timestamp_bereq}\t${fmt_timestamp_beresp}\t${fmt_timestamp_berespbody}\t${fmt_timestamp_retry}\t${fmt_timestamp_error}\t"

/usr/local/bin/varnishmtail-wrapper "${PROGS}" "${PORT}" varnishmtail-internal "${FMT}"
