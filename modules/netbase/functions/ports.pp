# SPDX-License-Identifier: Apache-2.0
# @summary function to return a hash of service definitions
# @param filter a list of ports used to ensure we only return services matching the ports
function netbase::ports (
    Variant[Stdlib::Port, Array[Stdlib::Port]] $filter = []
) >> Hash[String, Netbase::Service] {
    include netbase
    if $filter.empty {
        $netbase::all_services
    } else {
        $netbase::all_services.filter |$item| {
            $item[1]['port'] in Array($filter, true)
        }
    }
}
