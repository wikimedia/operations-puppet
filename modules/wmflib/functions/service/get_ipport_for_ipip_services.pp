# SPDX-License-Identifier: Apache-2.0
function wmflib::service::get_ipport_for_ipip_services(
    Hash[String, Wmflib::Service] $services,
    Wmflib::Sites $site,
) >> Array[String] {
    $services.filter |$lvs_name, $svc| {
        $site in $svc['ip'] and $svc['lvs'] and $svc['lvs']['ipip_encapsulation'] and $site in $svc['lvs']['ipip_encapsulation']
    }
    .map |$lvs_name, $svc| {
        $svc['ip'][$site].values().map|Stdlib::IP::Address $ip| {
          $ip_port = $ip? {
            Stdlib::IP::Address::V4 => "${ip}:${svc['port']}",
            Stdlib::IP::Address::V6 => "[${ip}]:${svc['port']}",
          }
        }
    }
    .flatten()
    .unique()
    .sort()
}
