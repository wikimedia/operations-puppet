# SPDX-License-Identifier: Apache-2.0
class profile::maps::tlsproxy(
    String $servicename      = lookup('profile::maps::tlsproxy::servicename'),
    String $ocsp_proxy       = lookup('http_proxy', {'default_value' => ''}),
){

    tlsproxy::localssl { $servicename:
        server_name    => $servicename,
        certs          => [$servicename],
        upstream_ports => [6533],
        default_server => true,
        do_ocsp        => false,
        ocsp_proxy     => $ocsp_proxy,
        enable_http2   => false,
    }

    ferm::service { 'maps-proxy-https':
        proto   => 'tcp',
        notrack => true,
        port    => '443',
    }
}
