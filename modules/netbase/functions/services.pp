# SPDX-License-Identifier: Apache-2.0
# @summary function to return a hash of service definitions
# @param a list of services to return.  if not provided all services are returned
function netbase::services (
    Variant[String,Array[String[1]]] $filter = []
) >> Hash[String, Netbase::Service] {
    $_filter = Array($filter, true)
    include netbase
    if $filter.empty {
        $netbase::all_services
    } else {
        $netbase::all_services.filter |$item| {
            # check the service key and the aliases
            $item[0] in $_filter or ($item[1]['aliases'] and !$item[1]['aliases'].intersection($_filter).empty)
        }
    }
}
