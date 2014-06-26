# manifests/role/subversion.pp

class role::subversion {

    system::role { 'role::subversion':
        description => 'public, read-only SVN server'
    }
    $svnhost = 'svn.wikimedia.org'

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

    monitor_service { 'https':
        description   => 'HTTPS',
        check_command => "check_ssl_cert!${svnhost}",
    }
}
