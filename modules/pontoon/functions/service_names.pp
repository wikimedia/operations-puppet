# SPDX-License-Identifier: Apache-2.0
# @summary Map each service to its 'names'. Names include the service name itself and any
#          configured discovery names.
# @param services_config The Wmflib::Service configuration to inspect
# @param domains The domains to map services to
# @param tld     The network's TLD
function pontoon::service_names(
    Hash[String, Wmflib::Service] $services_config,
    Array[String] $domains = ['discovery', 'svc.eqiad', 'svc.codfw'],
    String $tld = 'wmnet',
) >> Hash[String, Array[String]] {
    $t = $services_config.map |$service_name, $config| {
        $disc_names = ('discovery' in $config) ? {
          true  => $config['discovery'].map |$el| { $el['dnsdisc'] },
          false => [],
        }
        $aliases = ('aliases' in $config) ? {
          true  => $config['aliases'],
          false => [],
        }
        $all_names = unique($disc_names + $aliases + $service_name)

        $svc_names = $domains.map |$d| {
            $all_names.map |$n| {
                [ "${n}.${d}.${tld}" ]
            }
        }

        [
            $service_name,
            $svc_names.flatten().sort(),
        ]
    }

    Hash($t)
}

