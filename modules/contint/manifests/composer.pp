# == Class contint::composer
#
# Install composer as /usr/local/bin/composer using a Git repository from
# Gerrit. Useful until composer is properly packaged for our distributions.
#
class contint::composer {

    require ::contint::deployment_dir

    git::clone { 'jenkins CI Composer':
        ensure             => 'latest',
        directory          => '/srv/deployment/integration/composer',
        origin             => 'https://gerrit.wikimedia.org/r/integration/composer.git',
        recurse_submodules => true,
    }

    # Create a symlink for the composer executable
    file { '/usr/local/bin/composer':
        ensure => 'link',
        target => '/srv/deployment/integration/composer/vendor/bin/composer',
    }
}
