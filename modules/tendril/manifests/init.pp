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

    $ssl_settings = ssl_ciphersuite('apache', 'mid', true)

    if os_version('debian >= stretch') {
        $php_module = 'php7.0'
    } else {
        $php_module = 'php5'
    }

    class { '::httpd':
        modules => ['rewrite',
                    'headers',
                    'ssl',
                    $php_module,
                    'authnz_ldap',
                    ],
    }

    httpd::site { $site_name:
        content => template("tendril/apache/${site_name}.erb");
    }

    letsencrypt::cert::integrated { 'tendril':
        subjects   => $site_name,
        puppet_svc => 'apache2',
        system_svc => 'apache2',
    }

    require_package(
        'php5-mysql',
        'php5-memcache', # do not install -memcached, it won't work
        'memcached', # memcached expected by default on localhost
    )

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
    # we do not update (pull) automatically the repo
    # not adding ensure => 'latest' is on purpose
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
