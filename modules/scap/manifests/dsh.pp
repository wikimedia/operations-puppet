# == Class scap::dsh
#
# Sets up dsh config files alone, without actually
# setting up dsh. Useful primarily for monitoring and deploy servers.
#
# == Paramters:
#
# [*scap_proxies*]
#   List of FQDNs for servers to be used as scap rsync proxies. Default []
#
# [*scap_masters*]
#   List of FQDNs for servers to be used as scap masters. Default []
#
class scap::dsh (
    $groups = {},
    $scap_proxies = [],
    $scap_masters = [],
){
    package { 'dsh':
        ensure => present,
    }
    file { '/etc/dsh':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }
    file { '/etc/dsh/group':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    # Base dsh groups currently used
    create_resources('scap::dsh::group', $groups)

    file { '/etc/dsh/group/scap-proxies':
        content => join($scap_proxies, "\n"),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }

    file { '/etc/dsh/group/scap-masters':
        content => join($scap_masters, "\n"),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }

    file { '/etc/dsh/dsh.conf':
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/scap/dsh/dsh.conf',
    }
}
