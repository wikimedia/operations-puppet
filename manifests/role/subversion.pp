# manifests/role/subversion.pp

class role::subversion {

    system::role { 'role::subversion':
        description => 'public, read-only SVN server'
    }
    $svnhost = 'svn.wikimedia.org'

    install_certificate{ 'svn.wikimedia.org':
        ca => 'RapidSSL_CA.pem',
    }

    $ssl_settings = ssl_ciphersuite('apache-2.2', 'compat')

    class { '::subversion':
        host => $svnhost,
    }

    ferm::service { 'http':
        proto => 'tcp',
        port  => '80'
    }

    ferm::service { 'https':
        proto => 'tcp',
        port  => '443'
    }

    monitoring::service { 'https':
        description   => 'HTTPS',
        check_command => "check_ssl_cert!${svnhost}",
    }
}

