# manifests/role/subversion.pp

class role::subversion {

    system::role { 'role::subversion': description => 'public, read-only SVN server' }

    class { '::subversion': }

    monitor_service { 'https': description => 'HTTPS', check_command => 'check_ssl_cert!svn.wikimedia.org'}

    file { '/etc/apache2/sites-available/svn':
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/subversion/apache/svn.wikimedia.org',
    }
}

