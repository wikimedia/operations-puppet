# This module sets up Phragile.
# Phragile generates sprint overviews and data visualizations for projects in Phabricator.
#
# This installs and sets up:
# - Apache
# - PHP
# - Composer
# - Phragile
#    - clone repository
#    - download Composer dependencies
#    - configure environment variables in .env
#    - set up cron job for snapshots
#    - run migrations
#
# Some manual configuration (e.g. MySQL config and Phabricator connection) needs to be done in the .env file to complete the installation.

class phragile(
    $install_dir = '/var/lib/phragile/phragile',
    $debug = false,
) {

    requires_realm('labs')
    if os_version('debian == jessie') {
        $php_module = 'php5'
    } else {
        $php_module = 'php'
    }

    class { '::httpd':
        modules => ['rewrite', $php_module],
    }

    require_package(
        "${php_module}-cli",
        "${php_module}-curl",
        "${php_module}-mysql",
        "${php_module}-mcrypt",
    )

    group { 'phragile':
        ensure => present,
    }

    $phragile_home = '/var/lib/phragile'

    user { 'phragile':
        ensure     => present,
        home       => $phragile_home,
        shell      => '/bin/bash',
        managehome => true,
        system     => true,
    }

    git::clone { 'phragile':
        ensure    => latest,
        directory => $install_dir,
        owner     => 'phragile',
        group     => 'phragile',
        origin    => 'https://github.com/wmde/phragile.git',
    }

    exec { 'mcrypt':
        command => "/usr/sbin/${php_module}enmod mcrypt",
        unless  => '/usr/bin/php -m | /bin/grep -q mcrypt',
        require => [Package["${php_module}-mcrypt"], Package["${php_module}-cli"]],
    }

    exec { 'php_mysql':
        command => "/usr/sbin/${php_module}enmod mysql",
        unless  => '/usr/bin/php -m | /bin/grep -q mysql',
        require => [Package["${php_module}-mysql"], Package["${php_module}-cli"]],
    }

    $composer_dir = "${phragile_home}/composer"
    $composer     = "${composer_dir}/vendor/bin/composer"

    git::clone { 'composer':
        ensure             => 'latest',
        directory          => $composer_dir,
        origin             => 'https://gerrit.wikimedia.org/r/integration/composer.git',
        owner              => 'phragile',
        group              => 'phragile',
        recurse_submodules => true,
    }

    exec { 'composer_install':
        environment => "HOME=${phragile_home}",
        cwd         => $install_dir,
        command     => "${composer} install",
        user        => 'phragile',
        require     => [Git::Clone['phragile'], Git::Clone['composer'], Package["${php_module}-mcrypt"], Package["${php_module}-cli"]],
    }

    file { "${install_dir}/.env":
        content => template('phragile/env.erb'),
        require => Git::Clone['phragile'],
        replace => false,
        owner   => 'phragile',
        group   => 'phragile',

    }

    exec { 'update_phragile_app_key':
        command => template('phragile/update_app_key.erb'),
        cwd     => $install_dir,
        user    => 'phragile',
        unless  => "/bin/grep -q ^APP_KEY ${install_dir}/.env",
        require => Exec['composer_install'],
    }

    httpd::conf { 'apache_conf':
        ensure  => present,
        content => template('phragile/apache.conf.erb'),
    }

    file { "${install_dir}/storage":
        ensure  => directory,
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '0775',
        recurse => true,
        require => Git::Clone['phragile'],
    }

    exec { '/usr/bin/php artisan migrate':
        cwd     => $install_dir,
        user    => 'phragile',
        unless  => "/bin/grep -q 'DB_USERNAME=$' ${install_dir}/.env",
        require => Exec['composer_install'],
    }

    cron { 'daily_snapshots':
        ensure  => present,
        command => "/usr/bin/php ${install_dir}/artisan snapshots:create 2>&1 | logger -t phragile-snapshots",
        user    => 'phragile',
        hour    => '2',
        minute  => '0',
        require => Exec['composer_install'],
    }
}
