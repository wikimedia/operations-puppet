# SPDX-License-Identifier: Apache-2.0
# @summary cloudlb logic for wiki replicas, based on etcd
class profile::wmcs::cloudlb::haproxy_wikireplicas (
    Hash[String[1], Hash[String[1], Stdlib::IP::Address::Nosubnet]] $frontends     = lookup('profile::wmcs::cloudlb::haproxy_wikireplicas::frontends', {default_value => {}}),
    Hash[String[1], Stdlib::Port]                                   $section_ports = lookup('profile::mariadb::section_ports'),
) {
    if !$frontends.empty() {
        include profile::confd

        $replica_type_backups = {
            'analytics' => 'web',
            'web'       => 'analytics',
        }

        $replica_sections = ['s1', 's2', 's3', 's4', 's5', 's6', 's7', 's8']
        $replica_section_ports = $section_ports.filter |String[1] $section, Stdlib::Port $port| { $section in $replica_sections }

        class { 'cloudlb::haproxy::wikireplicas::backend':
            replica_types => $replica_type_backups.keys,
            sections      => $replica_section_ports,
        }

        class { 'cloudlb::haproxy::wikireplicas::frontend':
            frontends => $frontends,
            backups   => $replica_type_backups,
        }

        $ips = $frontends.values.map |Hash $hash| { $hash.values }.flatten.sort
        firewall::service { 'cloudlb-haproxy-wiki-replicas':
            proto    => 'tcp',
            port     => [3306],
            src_sets => ['CLOUD_NETWORKS'],
            drange   => $ips,
        }
    }
}
