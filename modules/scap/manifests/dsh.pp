# == Class scap::dsh
#
# Sets up dsh config files alone, without actually
# setting up dsh. Useful primarily for monitoring and deploy servers.
#
# == Paramters:
# [*group_source*]
#   Puppet file source for /etc/dsh/group.
#   Default 'puppet:///modules/dsh/group'
#
# [*scap_proxies*]
#   List of FQDNs for servers to be used as scap rsync proxies. Default []
#
# [*scap_masters*]
#   List of FQDNs for servers to be used as scap masters. Default []
#
# [*mediawiki_installation*]
#   List of FQDNs for servers to be used for mediawiki installs. Default []
#
class scap::dsh (
    $group_source = 'puppet:///modules/scap/dsh/group',
    $scap_proxies = [],
    $scap_masters = [],
    $mediawiki_installation = [],
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

    file { '/etc/dsh/group/scap-masters':
        content => join($scap_masters, "\n"),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }

    file { '/etc/dsh/group/mediawiki-installation':
        content => join($mediawiki_installation, "\n"),
        owner => 'root',
        group => 'root',
        mode  => '0444',
    }

    file { '/etc/dsh/dsh.conf':
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/scap/dsh/dsh.conf',
    }
}
