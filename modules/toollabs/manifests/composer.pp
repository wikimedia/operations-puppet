# Install composer (https://getcomposer.org/) to
# /usr/local/bin/composer and keep it updated.  This class is based on
# contint::composer

class toollabs::composer {

    file { '/srv/composer':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    git::clone { 'composer':
        ensure             => 'latest',
        directory          => '/srv/composer',
        origin             => 'https://gerrit.wikimedia.org/r/integration/composer.git',
        recurse_submodules => true,
        require            => File['/srv/composer'],
    }

    # Create a symbolic link for the composer executable.
    file { '/usr/local/bin/composer':
        ensure  => 'link',
        target  => '/srv/composer/vendor/bin/composer',
        owner   => 'root',
        group   => 'root',
        require => Git::Clone['composer'],
    }
}
