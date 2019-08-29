# wikistats host role class
# this is labs-only - https://wikistats.wmflabs.org (dzahn)
# NOT stats.wikimedia.org (analytics)
# these projects are often confused
#
# filtertags: labs-project-wikistats
class role::wikistats::instance {

    system::role { 'wikistats': description => 'wikistats instance' }

    $php_module = 'php7.0'

    class { '::httpd':
        modules => [$php_module, 'rewrite'],
    }

    class { '::mariadb::packages': }

    class { '::mariadb::config':
        basedir => '/usr',
        datadir => '/srv/sqldata',
    }

    include ::profile::wikistats

}
