# tendril: MariaDB Analytics
# git clones from operations/software/tendril to /srv/tendril

class tendril (
    $site_name,
    $docroot,
    $ldap_binddn,
    $ldap_authurl,
    $ldap_groups,
    $auth_name,
    $cas_enable=false,
) {

    include passwords::ldap::production
    include passwords::tendril
    $proxypass = $passwords::ldap::production::proxypass
    $tendril_user_web = $passwords::tendril::db_user_web
    $tendril_pass_web = $passwords::tendril::db_pass_web

    $ssl_settings = ssl_ciphersuite('apache', 'strong', true)

    if $cas_enable {
        include profile::idp::client::httpd  # lint:ignore:wmf_styleguide
    } else {
        httpd::site { $site_name:
          content => template("tendril/apache/${site_name}.erb");
      }
    }

    acme_chief::cert { 'tendril':
        puppet_svc => 'apache2',
    }

    # Temporary hack while jessie is supported
    if debian::codename::le('jessie') {
        ensure_packages([
            'php5-mysql',
            'php5-memcache', # do not install -memcached, it won't work
            'memcached', # memcached expected by default on localhost
        ])
    } else {
        $php56_packages = [
            'libapache2-mod-php5.6',
            'php5.6-cli',
            'php5.6-common',
            'php5.6-curl',
            'php5.6-dev',
            'php5.6-gd',
            'php5.6-gmp',
            'php5.6-intl',
            'php5.6-ldap',
            'php5.6-mcrypt',
            'php5.6-mysql',
            'php5.6-pgsql',
            'php5.6-readline',
            'php5.6-sqlite3',
            'php5.6-tidy',
            'php5.6-xsl',
        ]

        apt::package_from_component { 'tendril_php56':
            component => 'component/php56',
            packages  => $php56_packages,
        }
    }

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
        owner     => 'mwdeploy',
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
