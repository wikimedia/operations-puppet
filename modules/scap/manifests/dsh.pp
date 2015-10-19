# == Class scap::dsh
#
# Sets up dsh config files alone, without actually
# setting up dsh. Useful primarily for monitoring
class scap::dsh (
    $group_source = 'puppet:///modules/scap/dsh/group',
    $scap_proxies = [],
){
    file { '/etc/dsh':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }
    file { '/etc/dsh/group':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => $group_source,
        recurse => true,
    }

    file { '/etc/dsh/group/scap-proxies':
        content => join($scap_proxies, "\n"),
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
