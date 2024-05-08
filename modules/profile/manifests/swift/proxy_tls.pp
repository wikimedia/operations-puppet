# SPDX-License-Identifier: Apache-2.0
class profile::swift::proxy_tls (
    String $ocsp_proxy = lookup('http_proxy', {'default_value' => ''}),
){
    include profile::tlsproxy::envoy

    ferm::service { 'swift-proxy-https':
        proto   => 'tcp',
        notrack => true,
        port    => '443',
    }
}
