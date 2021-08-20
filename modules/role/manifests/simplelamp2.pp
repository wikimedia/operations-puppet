# = class: role::simplelamp2
#
# Sets up a simple LAMP server for use by arbitrary php applications
#
# httpd ("apache"), memcached, PHP, MariaDB
#
# As opposed to the original simplelamp role it uses
# MariaDB instead of MySQL and the httpd instead of the apache module.
#
# filtertags: labs-common
class role::simplelamp2 {

    system::role { 'simplelamp2':
        ensure      => 'present',
        description => 'httpd, memcached, PHP, mariadb',
    }

    $apache_modules_common = ['rewrite', 'headers']

    ensure_packages('libapache2-mod-php')

    # TODO: another use case for php_version fact
    $apache_php_module = debian::codename() ? {
        'stretch'  => 'php7.0',
        'buster'   => 'php7.3',
        'bullseye' => 'php7.4',
        default    => fail("unsupported on ${debian::codename()}"),
    }

    $apache_modules = concat($apache_modules_common, $apache_php_module)

    class { 'httpd':
        modules             => $apache_modules,
        purge_manual_config => false,
    }

    class { 'memcached':
        # TODO: the following were implicit defaults from
        # MW settings, need to be reviewed.
        growth_factor => 1.05,
        min_slab_size => 5,
    }

    include profile::mariadb::generic_server
}
