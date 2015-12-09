class toollabs::composer {
    # based on contint::slave_scripts

    file { '/srv/composer':
        ensure => 'directory',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }

    git::clone { 'composer':
        ensure             => 'latest',
        directory          => '/srv/composer',
        origin             => 'https://gerrit.wikimedia.org/r/p/integration/composer.git',
        recurse_submodules => true,
        require            => File['/srv/composer'],
    }

    # Create a symlink for the composer executable
    file { '/usr/local/bin/composer':
        ensure  => 'link',
        target  => '/srv/composer/vendor/bin/composer',
        owner   => 'root',
        group   => 'root',
        require => Git::Clone['composer'],
    }
}
