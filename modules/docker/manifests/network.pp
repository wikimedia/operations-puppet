# SPDX-License-Identifier: Apache-2.0
# @summary Manage a Docker network
# @param ensure Ensure of the resources that support it
# @param subnet Network subnet. Note that if multiple docker::network
#               resources are defined, they must not specify overlapping
#               subnets.
# @param driver Network driver (bridge, overlay)
define docker::network(
    Wmflib::Ensure $ensure,
    Stdlib::IP::Address $subnet,
    Enum['bridge', 'overlay'] $driver = 'bridge',
) {
    if $ensure == 'present' {
        exec { "create-docker-network-${title}":
            command => @("CMD"/L$)
                /usr/bin/docker network create \
                --driver='${driver}' \
                --subnet='${subnet}' \
                '${title}'
                |- CMD
            ,
            unless  => "/usr/bin/docker network ls --format '{{.Name}}' | grep -q '^${title}$'",
        }
    } else {
        exec { "remove-docker-network-${title}":
            command => "/usr/bin/docker network rm '${title}'",
            onlyif  => "/usr/bin/docker network ls --format '{{.Name}}' | grep -q '^${title}$'",
        }
    }
}
