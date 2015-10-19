# == Class scap::dsh
#
# Sets up dsh config files alone, without actually
# setting up dsh. Useful primarily for monitoring and deploy servers.
#
# == Paramters:
# [*mediawiki_installation*]
#   List of FQDNs for servers to be used as mediawiki installs. Default []
#
# [*scap_proxies*]
#   List of FQDNs for servers to be used as scap rsync proxies. Default []
#
# [*scap_masters*]
#   List of FQDNs for servers to be used as scap masters. Default []
#
class scap::dsh (
    $mediawiki_installation = [],
    $scap_proxies = [],
    $scap_masters = [],
){
    file { '/etc/dsh':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }
    file { '/etc/dsh/group':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }

    file { '/etc/dsh/group/mediawiki-installation':
        content => join($mediawiki_installation, "\n"),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
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

    file { '/etc/dsh/dsh.conf':
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/scap/dsh/dsh.conf',
    }
}
