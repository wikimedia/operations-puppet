# Class puppetmaster::puppetdb
#
# Sets up a puppetdb instance and the corresponding database server.
class puppetmaster::puppetdb(
    $master,
    $port       = 443,
    $jetty_port = 8080,
    $jvm_opts   ='-Xmx4G',
    $puppetdb_major_version=undef,
    $puppetdb_package_variant=undef,
) {
    requires_os('debian >= jessie')

    $puppetdb_pass = hiera('puppetdb::password::rw')

    ## TLS Termination
    # Set up nginx as a reverse-proxy
    ::base::expose_puppet_certs { '/etc/nginx':
        ensure          => present,
        provide_private => true,
        require         => Class['nginx'],
    }

    $ssl_settings = ssl_ciphersuite('nginx', 'mid')
    include ::sslcert::dhparam
    ::nginx::site { 'puppetdb':
        ensure  => present,
        content => template('puppetmaster/nginx-puppetdb.conf.erb'),
        require => Class['::sslcert::dhparam'],
    }

    diamond::collector::nginx{ $::fqdn:
        port => 10080,
    }

    ## PuppetDB installation

    class { 'puppetdb::app':
        db_rw_host               => $master,
        db_ro_host               => $::fqdn,
        db_password              => $puppetdb_pass,
        perform_gc               => ($master == $::fqdn), # only the master must perform GC
        jvm_opts                 => $jvm_opts,
        puppetdb_major_version   => $puppetdb_major_version,
        puppetdb_package_variant => $puppetdb_package_variant,
    }
}
