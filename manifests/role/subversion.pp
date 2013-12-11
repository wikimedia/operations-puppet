# manifests/role/subversion.pp

class role::subversion {

    system::role { 'role::subversion': description => 'public, read-only SVN server' }

    class { '::subversion':
        host => 'svn.wikimedia.org',
    }

    monitor_service { 'https': description => 'HTTPS', check_command => "check_ssl_cert!${host}"}

}

