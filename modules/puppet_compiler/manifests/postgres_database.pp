class puppet_compiler::postgres_database {

    # set ssldir to location of the local catalog-differ puppet CA.
    # this allows catalog-differ runs to validate local puppetdb connections.
    $ssldir='/var/lib/catalog-differ/puppet/ssl'

    class { '::profile::puppetdb':
        ssldir => $ssldir,
    }

    class { '::profile::puppetdb::database':
        ssldir => $ssldir,
    }

    file { '/etc/puppetdb/ssl/ca.pem':
        source => "${ssldir}/certs/ca.pem",
        owner  => "puppetdb",
        before => Service['puppetdb']
    }

}
