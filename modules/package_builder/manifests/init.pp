class package_builder {
    package { [
        'cowbuilder',
        'build-essential',
        'fakeroot',
        'debhelper',
        'devscripts',
        'dh-make',
        'dh-autoreconf',
        'git-buildpackage',
        'zip',
        'unzip',
        'debian-archive-keyring',
        'ubuntu-archive-keyring',
        ]:
        ensure => present,
    }

    pbuilder_base { 'precise':
        distribution => 'precise',
        components   => 'main universe',
        mirror       => 'http://nova.clouds.archive.ubuntu.com/ubuntu/',
        keyring      => '/usr/share/keyrings/ubuntu-archive-keyring.gpg',
    }
    pbuilder_base { 'trusty':
        distribution => 'trusty',
        components   => 'main universe',
        mirror       => 'http://nova.clouds.archive.ubuntu.com/ubuntu/',
        keyring      => '/usr/share/keyrings/ubuntu-archive-keyring.gpg',
    }
    pbuilder_base { 'jessie':
        distribution => 'jessie',
        components   => 'main',
        mirror       => 'http://mirrors.wikimedia.org/debian',
        keyring      => '/usr/share/keyrings/debian-archive-keyring.gpg',
    }
    pbuilder_base { 'sid':
        distribution => 'sid',
        components   => 'main',
        mirror       => 'http://mirrors.wikimedia.org/debian',
        keyring      => '/usr/share/keyrings/debian-archive-keyring.gpg',
    }

    file { '/var/cache/pbuilder/hooks':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { '/etc/pbuilderrc':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/package_builder/pbuilderrc',
    }

    Package['cowbuilder'] -> File['/etc/pbuilderrc']
    File['/etc/pbuilderrc'] -> File['/var/cache/pbuilder/hooks']
    File['/var/cache/pbuilder/hooks'] -> Pbuilder_base['precise']
    File['/var/cache/pbuilder/hooks'] -> Pbuilder_base['trusty']
    File['/var/cache/pbuilder/hooks'] -> Pbuilder_base['jessie']
    File['/var/cache/pbuilder/hooks'] -> Pbuilder_base['sid']
}
