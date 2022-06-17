# SPDX-License-Identifier: Apache-2.0
# https://racktables.wikimedia.org
## Please note that Racktables is a tarball extraction based installation
## into its web directory root.  This means that puppet cannot fully automate
## the installation at this time & the actual tarball must be downloaded from
## http://racktables.org/ and unzipped into /srv/org/wikimedia/racktables
class racktables(
    Stdlib::Host $racktables_host,
    Stdlib::Host $racktables_db_host,
    String $racktables_db,
){

    ensure_packages(['php-mysql', 'php-gd'])

    # TODO: another use case for a php_version fact
    $php_ini = debian::codename::eq('buster') ? {
        true    => '/etc/php/7.3/apache2/php.ini',
        default => '/etc/php/7.0/apache2/php.ini',
    }

    file { [
        '/srv/org',
        '/srv/org/wikimedia',
        '/srv/org/wikimedia/racktables',
        '/srv/org/wikimedia/racktables/wwwroot',
        '/srv/org/wikimedia/racktables/wwwroot/inc',
    ]:
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { '/srv/org/wikimedia/racktables/wwwroot/inc/secret.php':
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('racktables/racktables.config.erb'),
    }

    # Increase the default memory limit T102092
    file_line { 'racktables_php_memory':
        path   => $php_ini,
        line   => 'memory_limit = 256M',
        match  => '^\s*memory_limit',
        notify => Service['apache2'],
    }

    # Authentication is provided by CAS and only ops are allowed access
    file_line {'make everyone admin':
        path    => '/srv/org/wikimedia/racktables/wwwroot/inc/auth.php',
        line    => "\t\t\t\$remote_username = 'admin';",
        match   => '^\s+\$remote_username\s+=\s+\$_SERVER\[\'REMOTE_USER\'\];',
        replace => true,
    }
}
