# Class puppetmaster::puppetdb
#
# Sets up a puppetdb instance and the corresponding database server.
class puppetmaster::puppetdb(
    $master,
    $port       = 443,
    $jetty_port = 8080,
    $jvm_opts   ='-Xmx4G',
    $puppetdb_major_version=undef,
    $ssldir = undef,
    $ca_path = '/etc/ssl/certs/Puppet_Internal_CA.pem',
) {
    $puppetdb_pass = hiera('puppetdb::password::rw')

    ## TLS Termination
    # Set up nginx as a reverse-proxy
    ::base::expose_puppet_certs { '/etc/nginx':
        ensure          => present,
        provide_private => true,
        require         => Class['nginx'],
        ssldir          => $ssldir,
    }

    $ssl_settings = ssl_ciphersuite('nginx', 'mid')
    include ::sslcert::dhparam
    ::nginx::site { 'puppetdb':
        ensure  => present,
        content => template('puppetmaster/nginx-puppetdb.conf.erb'),
        require => Class['::sslcert::dhparam'],
    }

    # T209709
    nginx::status_site { $::fqdn:
        port => 10080,
    }

    ## PuppetDB installation

    if $puppetdb_major_version == 4 {
        apt::repository { 'wikimedia-puppetdb4':
            uri        => 'http://apt.wikimedia.org/wikimedia',
            dist       => "${::lsbdistcodename}-wikimedia",
            components => 'component/puppetdb4',
            before     => Class['puppetdb::app'],
        }
    }

    class { 'puppetdb::app':
        db_rw_host             => $master,
        db_ro_host             => $::fqdn,
        db_password            => $puppetdb_pass,
        perform_gc             => ($master == $::fqdn), # only the master must perform GC
        jvm_opts               => $jvm_opts,
        puppetdb_major_version => $puppetdb_major_version,
        ssldir                 => $ssldir,
        ca_path                => $ca_path,
    }
}
