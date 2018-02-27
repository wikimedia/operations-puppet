# == Class puppetmaster::puppetdb::client
# Configures a puppetmaster to work as a puppetdb client
class puppetmaster::puppetdb::client(
    $host,
    $port=443,
    $puppetdb_major_version=undef,
) {
    # Only 3.5+ puppetmasters can work with our version of puppetdb
    requires_os('debian >= jessie')

    if $puppetdb_major_version == 4 {
        $puppetdb_terminus_package = 'puppetdb-termini'
        $puppetdb_conf_template    = 'puppetmaster/puppetdb4.conf.erb'
    } else {
        $puppetdb_terminus_package = 'puppetdb-terminus'
        $puppetdb_conf_template    = 'puppetmaster/puppetdb.conf.erb'
    }

    require_package($puppetdb_terminus_package)

    file { '/etc/puppet/puppetdb.conf':
        ensure  => present,
        content => template($puppetdb_conf_template),
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
    }

    if defined(Service['apache2']) {
        File['/etc/puppet/routes.yaml'] -> Service['apache2']
    }

    # Absence of this directory causes the puppetmaster to spit out
    # 'Removing mount "facts": /var/lib/puppet/facts does not exist or is not a directory'
    # and catalog compilation to fail with https://tickets.puppetlabs.com/browse/PDB-949
    file { '/var/lib/puppet/facts':
        ensure => directory,
    }
}
