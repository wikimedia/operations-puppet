# == Class puppetmaster::puppetdb::client
# Configures a puppetmaster to work as a puppetdb client
class puppetmaster::puppetdb::client($host, $port=443) {
    # Only 3.5+ puppetmasters can work with our version of puppetdb
    requires_os('debian >= jessie')

    require_package('puppetdb-terminus')

    file { '/etc/puppet/puppetdb.conf':
        ensure  => present,
        content => template('puppetmaster/puppetdb.conf.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }

    file { '/etc/puppet/routes.yaml':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/puppetmaster/routes.yaml',
        notify => Service['apache2'],
    }

    # Absence of this directory causes the puppetmaster to spit out
    # 'Removing mount "facts": /var/lib/puppet/facts does not exist or is not a directory'
    # and catalog compilation to fail with https://tickets.puppetlabs.com/browse/PDB-949
    file { '/var/lib/puppet/facts':
        ensure => directory,
    }
}
