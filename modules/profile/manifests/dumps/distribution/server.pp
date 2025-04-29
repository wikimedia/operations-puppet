# SPDX-License-Identifier: Apache-2.0
# Profile for Dumps distribution server in the Public VLAN,
# that serves dumps to Cloud VPS/Stat boxes via NFS,
# or via web or rsync to mirrors

class profile::dumps::distribution::server {
    class { 'dumpsuser': }

    file { '/srv/dumps':
        ensure => 'directory',
    }

    # The following authorized_key exists in order to permit the dumpsgen user to send dumps from pods
    # running on the dse-k8s cluster. The receiving command is forced to be the rsync server and it
    # only permits access from the DSE_KUBEPODS_NETWORKS. The corresponding private key is deployed as
    # a Kubernetes secret in the mediawiki-dumps-legacy namespace of the dse-k8s-eqiad cluster.
    # See #T390738 for details.
    ssh::userkey { 'dumpsgen':
        source => 'puppet:///modules/profile/dumps/distribution/dumpsgen_authorized_keys',
    }

    # Allow SSH from the dse-k8s pods
    firewall::service { 'ssh_dse-K8s_pods':
        proto    => 'tcp',
        port     => 22,
        src_sets => ['DSE_KUBEPODS_NETWORKS'],
    }

    file { '/etc/default/smartmontools':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/profile/dumps/distribution/smartmontools',
    }

    # This profile expects a large volume mounted at /srv/dumps. That isn't
    #  puppetized, since it's likely set up by hand (thanks partman!) and
    #  defined with a server-specific uuid.
    #mount { '/srv/dumps':
        #ensure  => mounted,
        #fstype  => ext4,
        #options => 'defaults,noatime',
        #atboot  => true,
        #device  => '/dev/data/dumps',
        #require => File['/srv/dumps'],
    #}
}
