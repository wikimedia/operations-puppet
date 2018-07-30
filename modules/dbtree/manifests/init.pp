# https://dbtree.wikimedia.org/
class dbtree {

    # dbtree requires apache which is provided by profile::tendril::webserver

    # dbtree config
    include passwords::tendril
    $tendril_user_web = $passwords::tendril::db_user_web
    $tendril_pass_web = $passwords::tendril::db_pass_web


    file { ['/srv/dbtree']:
        ensure  => 'directory',
        owner   => 'mwdeploy',
        group   => 'www-data',
        mode    => '0755',
        require => User['mwdeploy'],
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
}
