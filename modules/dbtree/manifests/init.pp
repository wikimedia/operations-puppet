# https://dbtree.wikimedia.org/
class dbtree {

    # dbtree requires apache, which should be provided by the role
    # include ::apache # lint:ignore:wmf_styleguide

    if os_version('debian >= stretch') {
        # Please note dbtree doesn't currently work on stretch's php
        require_package('libapache2-mod-php')
        require_package('php-mysql')
    } else {
        require_package('libapache2-mod-php5')
        require_package('php5-mysql')
    }

    httpd::site { 'dbtree.wikimedia.org':
        content => template('dbtree/dbtree.wikimedia.org.erb'),
    }

    # dbtree config
    include passwords::tendril
    $tendril_user_web = $passwords::tendril::db_user_web
    $tendril_pass_web = $passwords::tendril::db_pass_web



    file { ['/srv/dbtree']:
        ensure => 'directory',
        owner  => 'mwdeploy',
        group  => 'mwdeploy',
    }

    git::clone { 'operations/software/dbtree':
    # we do not update (pull) automatically the repo
    # not adding ensure => 'latest' is on purpose
        directory => '/srv/dbtree',
        branch    => 'master',
        owner     => 'mwdeploy',
        group     => 'mwdeploy',
        require   => File['/srv/dbtree'],
    }

    file { '/srv/dbtree/inc/config.php':
        ensure  => 'present',
        owner   => 'mwdeploy',
        group   => 'mwdeploy',
        content => template('dbtree/dbtree.config.php.erb'),
        require => Git::Clone['operations/software/dbtree']
    }

    # Monitoring
    monitoring::service { 'http-dbtree':
        description   => 'HTTP-dbtree',
        check_command => 'check_http_url!dbtree.wikimedia.org!http://dbtree.wikimedia.org'
    }

}

