# SPDX-License-Identifier: Apache-2.0
# == Class: cephadm::cephadm
#
# @summary Prepares a node to be the node from which cephadm is run,
# installing the cephadm package from a suitable component
# (e.g. thirdparty/ceph-reef), creating an ssh keypair for cephadm to
# use & exporting the pubkey, and templating out a suitable config file
# for the cluster.
#
# @param Optional[String] ceph_repository_component
#     Component within our apt repo to install cephadm from
class cephadm::cephadm (
    Array[Stdlib::Host, 1] $osds,
    Array[Stdlib::Host, 1] $mons,
    Array[Stdlib::Host] $rgws,
    Hash $host_details,
    Hash[Stdlib::Host, String] $rack_locations,
    Wmflib::IP::Address::CIDR $mon_network,
    Optional[String] $rgw_realm = undef,
    Optional[String] $ceph_repository_component = 'thirdparty/ceph-reef',
    Optional[Wmflib::Ensure] $ensure = present,
) {
    apt::package_from_component { 'cephadm':
        component => $ceph_repository_component,
        packages  => ['cephadm'],
        priority  => 1002,
    }
    exec { 'Generate ssh keypair for cephadm use':
        # TODO: You could also use an array here, sometimes that is nice, avoids
        # parsing the command in the shell first
        command => '/usr/bin/ssh-keygen -C "cephadm root ssh key" -f /root/.ssh/id_cephadm -t ed25519 -N ""',
        creates => '/root/.ssh/id_cephadm.pub',
    }

    file { '/etc/cephadm':
        ensure => stdlib::ensure($ensure, 'directory'),
    }

    file { '/etc/cephadm/bootstrap-ceph.conf':
        ensure => $ensure,
        source => 'puppet:///modules/cephadm/bootstrap-ceph.conf',
    }

    file { '/etc/cephadm/osd_spec.yaml':
        ensure => $ensure,
        source => 'puppet:///modules/cephadm/osd_spec.yaml',
    }

    file { '/etc/cephadm/hosts.yaml':
        ensure  => $ensure,
        content => epp('cephadm/hosts.epp', {
            'mon_network'    => $mon_network,
            'osds'           => $osds,
            'mons'           => $mons,
            'rgws'           => $rgws,
            'host_details'   => $host_details,
            'rack_locations' => $rack_locations,
        }),
    }

    if $rgw_realm {
        file { '/etc/cephadm/zone_spec.yaml':
            ensure    => $ensure,
            show_diff => false,
            content   => epp('cephadm/zone_spec.epp', {
                'rgw_realm' => $rgw_realm,
                'zone'      => $::site,
            }),
        }
        file { '/etc/cephadm/rgw_spec.yaml':
            ensure  => $ensure,
            content => epp('cephadm/rgw_spec.epp', {
                'rgw_realm' => $rgw_realm,
                'zone'      => $::site,
            }),
        }
    }
}
