# SPDX-License-Identifier: Apache-2.0
# @summary Manages access firewall rules for the cloudinfra etcd cluster
class profile::wmcs::etcd::cloudinfra_firewall (
    Stdlib::Port        $adv_client_port = lookup('profile::wmcs::etcd::adv_client_port', {default_value => 2379}),
    Array[Stdlib::Fqdn] $waf_hosts       = lookup('profile::wmcs::waf::waf_hosts'),
) {
    # allow the waf nodes running the hiddenparma app and related tooling
    firewall::service { 'etcd-waf':
        proto  => 'tcp',
        port   => $adv_client_port,
        srange => $waf_hosts,
    }

    # allow the novaproxy hosts in the project-proxy project to talk to etcd
    firewall::service { 'etcd-novaproxy':
        proto    => 'tcp',
        port     => $adv_client_port,
        src_sets => ['CACHES'],
    }
}
