class profile::puppet_compiler::puppetdb (
    Stdlib::Unixpath $ssldir = lookup('profile::puppet_compiler::puppetdb::ssldir'),
    Stdlib::Fqdn     $master = lookup('profile::puppet_compiler::puppetdb::master'),
) {
    include puppet_compiler
    class { 'puppetmaster::puppetdb::client':
        hosts => [$::fqdn],
    }
    # puppetdb configuration
    file { "${puppet_compiler::vardir}/puppetdb.conf":
        source  => '/etc/puppet/puppetdb.conf',
        owner   => $puppet_compiler::user,
        require => File['/etc/puppet/puppetdb.conf']
    }

    # copy the catalog-differ puppet CA to validate connections to puppetdb
    file { '/etc/puppetdb/ssl/ca.pem':
        source => "${ssldir}/certs/ca.pem",
        owner  => 'puppetdb',
        before => Service['puppetdb']
    }
    class {'profile::puppetdb':
        ca_path => '/etc/puppetdb/ssl/ca.pem',
        ssldir  => $ssldir,
        master  => $master,
    }
    class {'profile::puppetdb::database':
        ssldir => $ssldir,
        master => $master,
    }

    # TODO: convert to systemd::timer::job
    # periodic script to populate puppetdb. Run at 4 AM every sunday.
    cron { 'Populate puppetdb':
        command => "/usr/local/bin/puppetdb-populate --basedir ${puppet_compiler::libdir} > ${puppet_compiler::homedir}/puppetdb-populate.log 2>&1",
        user    => $puppet_compiler::user,
        hour    => 4,
        minute  => 0,
        weekday => 0,
    }
}
