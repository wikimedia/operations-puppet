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

    $ssl_settings = ssl_ciphersuite('apache', 'strong', true)

    httpd::site { $site_name:
        content => template("tendril/apache/${site_name}.erb");
    }

    acme_chief::cert { 'tendril':
        puppet_svc => 'apache2',
    }

    require_package(
        'php5-mysql',
        'php5-memcache', # do not install -memcached, it won't work
        'memcached', # memcached expected by default on localhost
    )

    group { 'mwdeploy':
        ensure => present,
        system => true,
    }

    user { 'mwdeploy':
        ensure     => present,
        shell      => '/bin/bash',
        home       => '/var/lib/mwdeploy',
        system     => true,
        managehome => true,
    }

    file { '/srv/tendril':
        ensure  => 'directory',
        owner   => 'mwdeploy',
        group   => 'www-data',
        mode    => '0755',
        require => User['mwdeploy'],
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
