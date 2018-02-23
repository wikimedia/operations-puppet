class puppet_compiler::postgres_database {

    include ::profile::puppetdb

    class { '::profile::puppetdb::database':
        # specify ssldir here to make postgres use local catalog-differ cert
        # allowing catalog-differ runs to validate local puppetdb connection.
        ssldir => '/var/lib/catalog-differ/puppet/ssl',
    }

}
