# tendril: MariaDB Analytics
# git clones from operations/software/tendril to /srv/tendril

class tendril (
    $site_name,
    $docroot,
    $ldap_binddn,
    $ldap_authurl,
    $ldap_groups,
    $auth_name,
) {

    include passwords::ldap::wmf_cluster
    include passwords::tendril
    $proxypass = $passwords::ldap::wmf_cluster::proxypass
    $tendril_user_web = $passwords::tendril::db_user_web
    $tendril_pass_web = $passwords::tendril::db_pass_web

    apache::site { $site_name:
        content => template("tendril/apache/${site_name}.erb");
    }
    require_package('php5-mysql')

    file { '/srv/tendril':
        ensure => 'directory',
        owner  => 'www-data',
        group  => 'www-data',
    }
    file { '/srv/tendril/web/robots.txt':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///modules/tendril/robots.txt',
        require => Git::Clone['operations/software/tendril'],
    }

    git::clone { 'operations/software/tendril':
        ensure    => 'latest',
        directory => '/srv/tendril',
        branch    => 'master',
        owner     => 'www-data',
        group     => 'www-data',
        require   => File['/srv/tendril'],
    }

    file { '/srv/tendril/lib/config.php':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('tendril/config.php.erb'),
        require => Git::Clone['operations/software/tendril'],
    }
}
