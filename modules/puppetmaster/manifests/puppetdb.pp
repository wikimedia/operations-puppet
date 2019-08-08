# Class puppetmaster::puppetdb
#
# Sets up a puppetdb instance and the corresponding database server.
class puppetmaster::puppetdb(
    Stdlib::Host               $master,
    Stdlib::Port               $port          = 443,
    Stdlib::Port               $jetty_port    = 8080,
    String                     $jvm_opts      ='-Xmx4G',
    Optional[Stdlib::Unixpath] $ssldir        = undef,
    Stdlib::Unixpath           $ca_path       = '/etc/ssl/certs/Puppet_Internal_CA.pem',
    Boolean                    $filter_job_id = false,
) {
    $puppetdb_pass = hiera('puppetdb::password::rw')

    ensure_packages(['libnginx-mod-http-lua'])
    # Open to suggestions for a more FHS location
    file {'/etc/nginx/lua':
        ensure =>  directory
    }
    file{'/etc/nginx/lua/filter_job_id.lua':
        ensure => file,
        source => 'puppet:///modules/puppetmaster/filter_job_id.lua'
    }
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

    if os_version('debian <= stretch') {
        apt::repository { 'wikimedia-puppetdb4':
            uri        => 'http://apt.wikimedia.org/wikimedia',
            dist       => "${::lsbdistcodename}-wikimedia",
            components => 'component/puppetdb4',
            before     => Class['puppetdb::app'],
        }
    }

    class { 'puppetdb::app':
        db_rw_host  => $master,
        db_ro_host  => $::fqdn,
        db_password => $puppetdb_pass,
        perform_gc  => ($master == $::fqdn), # only the master must perform GC
        jvm_opts    => $jvm_opts,
        ssldir      => $ssldir,
        ca_path     => $ca_path,
    }
}
