class package_builder {
    package { [
        'cowbuilder',
        'build-essential',
        'fakeroot',
        'debhelper',
        'devscripts',
        'dh-make',
        'git-buildpackage',
        'zip',
        'unzip',
        'debian-archive-keyring',
        ]:
        ensure => present,
    }

    pbuilder_base { 'precise':
        distribution => 'precise',
        components   => 'main universe',
        mirror       => 'http://nova.clouds.archive.ubuntu.com/ubuntu/',
    }
    pbuilder_base { 'trusty':
        distribution => 'trusty',
        components   => 'main universe',
        mirror       => 'http://nova.clouds.archive.ubuntu.com/ubuntu/',
    }
    pbuilder_base { 'jessie':
        distribution => 'trusty',
        components   => 'main',
        mirror       => 'http://ftp.us.debian.org/debian/',
        keyring      => '/usr/share/keyrings/debian-archive-keyring.gpg',
    }
    pbuilder_base { 'sid':
        distribution => 'sid',
        components   => 'main',
        mirror       => 'http://ftp.us.debian.org/debian/',
        keyring      => '/usr/share/keyrings/debian-archive-keyring.gpg',
    }

    file { '/var/cache/pbuilder/hooks':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    File['/var/cache/pbuilder/hooks'] -> Pbuilder_base['precise']
    File['/var/cache/pbuilder/hooks'] -> Pbuilder_base['trusty']
    File['/var/cache/pbuilder/hooks'] -> Pbuilder_base['jessie']
    File['/var/cache/pbuilder/hooks'] -> Pbuilder_base['sid']
}
