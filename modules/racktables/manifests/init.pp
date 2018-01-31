# https://racktables.wikimedia.org
## Please note that Racktables is a tarball extraction based installation
## into its web directory root.  This means that puppet cannot fully automate
## the installation at this time & the actual tarball must be downloaded from
## http://racktables.org/ and unzipped into /srv/org/wikimedia/racktables
class racktables ($racktables_host, $racktables_db_host, $racktables_db) {

    require_package('php5-mysql', 'php5-gd')

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

    httpd::site { 'racktables.wikimedia.org':
        content => template('racktables/racktables.wikimedia.org.erb'),
    }

    # Increase the default memory limit T102092
    file_line { 'racktables_php_memory':
        path    => '/etc/php5/apache2/php.ini',
        line    => 'memory_limit = 256M',
        match   => '^\s*memory_limit',
        notify  => Service['apache2'],
    }
}
