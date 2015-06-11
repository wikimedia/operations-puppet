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
    $install_dir = '/srv/phragile',
    $debug = false,
    $vhost_name = 'phragile.wmflabs.org',
) {

    requires_realm('labs')

    include ::apache
    include ::apache::mod::rewrite
    include ::apache::mod::php5

    package { [
        'php5-cli',
        'php5-mysql',
        'php5-mcrypt',
    ]:
        ensure => present,
    }

    group { 'phragile':
        ensure => present,
    }

    $phragile_home = '/home/phragile'

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
        origin    => 'https://github.com/wmde/phragile.git',
    }

    exec { 'mcrypt':
        command => '/usr/sbin/php5enmod mcrypt',
    }

    exec { 'php_mysql':
        command => '/usr/sbin/php5enmod mysql',
    }

    $composer_dir = "${phragile_home}/composer"
    $composer     = "${composer_dir}/vendor/bin/composer"

    git::clone { 'composer':
        ensure             => 'latest',
        directory          => $composer_dir,
        origin             => 'https://gerrit.wikimedia.org/r/p/integration/composer.git',
        owner              => 'phragile',
        group              => 'phragile',
        recurse_submodules => true,
    }

    exec { 'composer_install':
        environment => "HOME=${phragile_home}",
        cwd         => $install_dir,
        command     => "${composer} install",
        require     => [Git::Clone['phragile'], Git::Clone['composer']],
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
        unless  => "/bin/grep -q ^APP_KEY ${install_dir}/.env",
        require => Exec['composer_install'],
    }

    apache::site { $vhost_name:
        ensure  => present,
        content => template('phragile/apache.conf.erb'),
        require => Class['::apache::mod::rewrite'],
    }

    file { "${install_dir}/storage":
        ensure  => directory,
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '0775',
        recurse => true,
    }

    exec { '/usr/bin/php artisan migrate':
        cwd     => $install_dir,
        unless  => "/bin/grep -q 'DB_USERNAME=$' ${install_dir}/.env",
        require => Exec['composer_install'],
    }

    cron { 'daily_snapshots':
        ensure  => present,
        command => "php ${install_dir}/artisan snapshots:create",
        user    => 'phragile',
        hour    => '2',
        minute  => '0',
        require => Exec['composer_install'],
    }
}
