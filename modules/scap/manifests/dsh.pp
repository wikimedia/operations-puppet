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
class scap::dsh (
    $group_source = 'puppet:///modules/scap/dsh/group',
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
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    $appserver = conftool({cluster => 'appserver', service => 'apache2'})
    $api = conftool({cluster => 'api_appserver', service => 'apache2'})
    $parsoid = conftool({cluster => 'parsoid', service => 'parsoid'})


    file { '/etc/dsh/group/mediawiki-installation':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('scap/dsh/mediawiki-installation.erb')
    }

    file { '/etc/dsh/group/parsoid':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('scap/dsh/parsoid.erb')
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
