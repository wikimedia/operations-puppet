# https://noc.wikimedia.org/
# https://dbtree.wikimedia.org/
class noc {

    # NOC needs a working mediawiki installation at the moment
    include ::mediawiki

    include ::apache

    apache::def { 'HHVM': }

    include ::mediawiki::web::php_engine

    include ::apache::mod::rewrite
    include ::apache::mod::headers

    apache::site { 'noc.wikimedia.org':
        content => template('noc/noc.wikimedia.org.erb'),
    }

    apache::site { 'dbtree.wikimedia.org':
        content => template('noc/dbtree.wikimedia.org.erb'),
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
        content => template('noc/dbtree.config.php.erb'),
        require => Git::Clone['operations/software/dbtree']
    }

    # Monitoring
    monitoring::service { 'http-noc':
        description   => 'HTTP-noc',
        check_command => 'check_http_url!noc.wikimedia.org!http://noc.wikimedia.org'
    }

}
