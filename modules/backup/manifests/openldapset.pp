define backup::openldapset(){

    require_package('slapd') # slapcat is provided by the slapd package
    file { '/etc/bacula/scripts/openldap-pre':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0500',
        source => 'puppet:///modules/backup/openldap-pre',
    }

    file { '/etc/bacula/scripts/openldap-post':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0500',
        source => 'puppet:///modules/backup/openldap-post',
    }

    $run_scripts = {
        'ClientRunBeforeJob' => '/etc/bacula/scripts/openldap-pre',
        'ClientRunAfterJob' => '/etc/bacula/scripts/openldap-post',
    }
    bacula::client::job { 'openldap-backup':
        fileset     => 'openldap',
        jobdefaults => $role::backup::host::jobdefaults,
        extras      => $run_scripts,
    }
}
