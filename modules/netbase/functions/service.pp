# SPDX-License-Identifier: Apache-2.0
# @summary function to return a hash of service definitions
# @param filter the name of the service to return
function netbase::service (
    String[1] $filter
) >> Optional[Netbase::Service] {
    include netbase
    $netbase::all_services[$filter]
}
