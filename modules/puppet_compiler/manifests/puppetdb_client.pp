# @summary Configures a puppetmaster to work as a puppetdb client
# @param hosts the puppetdb hosts to configure
# @param port the port puppetdb uses
# @param command_broadcast brodcast to all puppetdb servers
# @param submit_only_hosts puppetdb submit only hosts
class puppet_compiler::puppetdb_client(
    Array[Stdlib::Host]     $hosts,
    Stdlib::Port            $port              = 443,
    Boolean                 $command_broadcast = false,
    Array[Stdlib::HTTPSUrl] $submit_only_hosts = [],
) {
    ensure_packages('puppet-terminus-puppetdb')

    file { '/etc/puppet':
        ensure => directory,
        mode   => '0444',
    }

    file { '/etc/puppet/puppetdb.conf':
        ensure  => file,
        content => template('puppet_compiler/puppetdb4.conf.erb'),
        mode    => '0444',
    }

    file { '/etc/puppet/routes.yaml':
        ensure => file,
        mode   => '0444',
        source => 'puppet:///modules/puppet_compiler/routes.yaml',
    }

    if defined(Service['apache2']) {
        File['/etc/puppet/routes.yaml', '/etc/puppet/puppetdb.conf'] -> Service['apache2']
    }

    # Absence of this directory causes the puppet server to spit out
    # 'Removing mount "facts": /var/lib/puppet/facts does not exist or is not a directory'
    # and catalog compilation to fail with https://tickets.puppetlabs.com/browse/PDB-949
    file { '/var/lib/puppet/facts':
        ensure => directory,
    }
}
