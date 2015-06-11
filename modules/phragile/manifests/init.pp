class phragile(
    $install_dir = '/srv/phragile',
    $debug = false,
    $vhost_name = 'phragile.wmflabs.org',
) {
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

    git::clone { 'phragile':
        directory => $install_dir,
        origin    => 'https://github.com/wmde/phragile.git',
        ensure    => 'latest',
    }

    $composer_home = '/home/composer' # TODO: Figure out where this should really go
    file { $composer_home:
        ensure  => directory,
    }

    exec { "mcrypt":
        command => '/usr/sbin/php5enmod mcrypt',
    }

    exec { "php_mysql":
        command => '/usr/sbin/php5enmod mysql',
    }

    $composer_dir = '/srv/composer'
    $composer     = "${composer_dir}/vendor/bin/composer"

    git::clone { 'composer':
        ensure             => 'latest',
        directory          => $composer_dir,
        origin             => 'https://gerrit.wikimedia.org/r/p/integration/composer.git',
        recurse_submodules => true,
    }

    exec { "composer_install":
        environment => "COMPOSER_HOME=${composer_home}",
        cwd         => $install_dir,
        command     => "${composer} install",
        require     => [Git::Clone['phragile'], Git::Clone['composer']],
    }

    file { "${install_dir}/.env":
        content => template('phragile/env.erb'),
        require => Git::Clone['phragile'],
        replace => false,
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
        ensure => present,
        command => "php ${install_dir}/artisan snapshots:create",
        hour => '2',
        minute => '0',
        require => Exec['composer_install'],
    }
}
