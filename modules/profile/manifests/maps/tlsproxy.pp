# SPDX-License-Identifier: Apache-2.0
class profile::maps::tlsproxy(
    String $servicename      = lookup('profile::maps::tlsproxy::servicename'),
    Boolean $use_pki         = lookup('profile::maps::tlsproxy::use_pki', {'default_value' => false}),
){
    if $use_pki {
        $cfssl_paths = profile::pki::get_cert('discovery', $facts['networking']['fqdn'], {
            hosts => ['maps.wikimedia.org', "kartotherian.svc.${::site}.wmnet"],
        })

        tlsproxy::localssl { $servicename:
            server_name    => $servicename,
            upstream_ports => [6533],
            default_server => true,
            enable_http2   => false,
            cfssl_paths    => $cfssl_paths,
            server_aliases => ['maps.wikimedia.org',"kartotherian.svc.${::site}.wmnet"],
        }
    } else {
        tlsproxy::localssl { $servicename:
            server_name    => $servicename,
            certs          => [$servicename],
            upstream_ports => [6533],
            default_server => true,
            enable_http2   => false,
        }
    }

    ferm::service { 'maps-proxy-https':
        proto   => 'tcp',
        notrack => true,
        port    => '443',
    }
}
