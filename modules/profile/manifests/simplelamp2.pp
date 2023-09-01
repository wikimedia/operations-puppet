# SPDX-License-Identifier: Apache-2.0
# Sets up a simple LAMP server for use by arbitrary php applications
#
# httpd ("apache"), memcached, PHP, MariaDB
#
# As opposed to the original simplelamp role it uses
# MariaDB instead of MySQL and the httpd instead of the apache module.
#
class profile::simplelamp2(
    Stdlib::Unixpath $database_datadir = lookup('profile::simplelamp2::database_datadir', {default_value => '/var/lib/mysql'}),
){

    $apache_modules_common = ['rewrite', 'headers']

    ensure_packages('libapache2-mod-php')

    # TODO: another use case for php_version fact
    $apache_php_module = debian::codename() ? {
        'buster'   => 'php7.3',
        'bullseye' => 'php7.4',
        default    => fail("unsupported on ${debian::codename()}"),
    }

    $apache_modules = concat($apache_modules_common, $apache_php_module)

    class { 'httpd::mpm':
        mpm    => 'prefork',
    }

    class { 'httpd':
        modules             => $apache_modules,
        purge_manual_config => false,
        require             => Class['httpd::mpm'],
    }

    class { 'memcached':
        # TODO: the following were implicit defaults from
        # MW settings, need to be reviewed.
        growth_factor => 1.05,
        min_slab_size => 5,
    }

    class { 'profile::mariadb::generic_server':
        datadir => $database_datadir,
    }
}
