class contint::slave_scripts {

    if $::realm == 'production' {
        fail('contint::slave_scripts must not be used in production. Slaves are already Trebuchet deployment targets.')
    }

    # Hack: faking directories that Trebuchet would normally manage.
    # The integration project in labs does not use Trebuchet to manage these
    # packages, but in production we do.
    if ! defined(File['/srv/deployment']) {
        file { '/srv/deployment':
            ensure => 'directory',
            mode   => '0755',
        }
    }
    if ! defined(File['/srv/deployment/integration']) {
        file { '/srv/deployment/integration':
            ensure => 'directory',
            mode   => '0755',
        }
    }

    git::clone { 'jenkins CI slave scripts':
        ensure             => 'latest',
        directory          => '/srv/deployment/integration/slave-scripts',
        origin             => 'https://gerrit.wikimedia.org/r/p/integration/jenkins.git',
        recurse_submodules => true,
    }
    git::clone { 'jenkins CI Composer':
        ensure             => 'latest',
        directory          => '/srv/deployment/integration/composer',
        origin             => 'https://gerrit.wikimedia.org/r/p/integration/composer.git',
        recurse_submodules => true,
    }

    # Create a symlink for the composer executable
    file { '/usr/local/bin/composer':
        ensure => 'link',
        target => '/srv/deployment/integration/composer/vendor/bin/composer',
    }

    git::clone { 'jenkins CI phpcs':
        ensure             => 'latest',
        directory          => '/srv/deployment/integration/phpcs',
        origin             => 'https://gerrit.wikimedia.org/r/p/integration/phpcs.git',
        recurse_submodules => true,
    }
    git::clone { 'jenkins CI phpunit':
        ensure             => 'latest',
        directory          => '/srv/deployment/integration/phpunit',
        origin             => 'https://gerrit.wikimedia.org/r/p/integration/phpunit.git',
        recurse_submodules => true,
    }
}
