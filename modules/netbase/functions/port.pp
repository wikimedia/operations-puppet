# SPDX-License-Identifier: Apache-2.0
# @summary function to return a hash of service definitions
# @param filter a list of ports used to ensure we only return services matching the ports
function netbase::port (
    Stdlib::Port $filter
) >> Optional[Netbase::Service] {
    include netbase
    netbase::ports($filter).values[0]
}
