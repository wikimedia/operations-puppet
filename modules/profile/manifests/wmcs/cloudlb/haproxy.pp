# SPDX-License-Identifier: Apache-2.0

class profile::wmcs::cloudlb::haproxy (
    CloudLB::HAProxy::Config $cloudlb_haproxy_config = lookup('profile::wmcs::cloudlb::haproxy::config'),
    String[1]                $acme_chief_cert_name   = lookup('profile::wmcs::cloudlb::haproxy::acme_chief_cert_name'),
) {
    acme_chief::cert { $acme_chief_cert_name:
        puppet_svc => 'haproxy',
    }

    class { 'haproxy':
        template => 'cloudlb/haproxy/haproxy.cfg.erb',
    }

    file { '/etc/haproxy/ipblocklist.txt':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/cloudlb/haproxy/ipblocklist.txt',
    }

    file { '/etc/haproxy/agentblocklist.txt':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/cloudlb/haproxy/agentblocklist.txt',
    }

    include network::constants
    class { 'cloudlb::haproxy::load_all_config':
        cloudlb_haproxy_config => $cloudlb_haproxy_config,
    }
}
