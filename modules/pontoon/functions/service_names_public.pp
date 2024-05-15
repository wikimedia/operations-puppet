# SPDX-License-Identifier: Apache-2.0
# @summary XXXX
# @param services_config The Wmflib::Service configuration to inspect
# @param domain The domain name where services are available
function pontoon::service_names_public(
    Hash[String, Wmflib::Service] $services_config,
    String $domain,
) >> Hash[String, Array[String]] {
    $t = $services_config.map |$service_name, $config| {
        $main_name = ('public_endpoint' in $config) ? {
            true  => ["${config['public_endpoint']}.${domain}"],
            false => [],
        }

        $aliases = ('public_aliases' in $config) ? {
            true  => $config['public_aliases'].map |$a| { "${a}.${domain}" },
            false => [],
        }

        [
            $service_name,
            ($main_name + $aliases).flatten().sort(),
        ]
    }

    Hash($t)
}
