# Class package_builder
# Packaging environment building class
#
# Actions:
#   Installs Debian package creation/building tools and creates environments to
#   help with easy package building.
#
# Parameters:
#   $basepath Untested, don't change it
# Usage:
#   include package_builder
class package_builder(
    $basepath='/var/cache/pbuilder',
) {
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

    # Pristine environments
    # amd64 architecture
    package_builder::pbuilder_base { 'precise-amd64':
        distribution => 'precise',
        components   => 'main universe',
        architecture => 'amd64',
        mirror       => 'http://nova.clouds.archive.ubuntu.com/ubuntu/',
        keyring      => '/usr/share/keyrings/ubuntu-archive-keyring.gpg',
    }
    package_builder::pbuilder_base { 'trusty-amd64':
        distribution => 'trusty',
        components   => 'main universe',
        architecture => 'amd64',
        mirror       => 'http://nova.clouds.archive.ubuntu.com/ubuntu/',
        keyring      => '/usr/share/keyrings/ubuntu-archive-keyring.gpg',
    }
    package_builder::pbuilder_base { 'jessie-amd64':
        distribution => 'jessie',
        components   => 'main',
        architecture => 'amd64',
        mirror       => 'http://mirrors.wikimedia.org/debian',
        keyring      => '/usr/share/keyrings/debian-archive-keyring.gpg',
    }
    package_builder::pbuilder_base { 'sid-amd64':
        distribution => 'sid',
        components   => 'main',
        architecture => 'amd64',
        mirror       => 'http://mirrors.wikimedia.org/debian',
        keyring      => '/usr/share/keyrings/debian-archive-keyring.gpg',
    }
    # i386 architecture
    package_builder::pbuilder_base { 'precise-i386':
        distribution => 'precise',
        components   => 'main universe',
        architecture => 'i386',
        mirror       => 'http://nova.clouds.archive.ubuntu.com/ubuntu/',
        keyring      => '/usr/share/keyrings/ubuntu-archive-keyring.gpg',
    }
    package_builder::pbuilder_base { 'trusty-i386':
        distribution => 'trusty',
        components   => 'main universe',
        architecture => 'i386',
        mirror       => 'http://nova.clouds.archive.ubuntu.com/ubuntu/',
        keyring      => '/usr/share/keyrings/ubuntu-archive-keyring.gpg',
    }
    package_builder::pbuilder_base { 'jessie-i386':
        distribution => 'jessie',
        components   => 'main',
        architecture => 'i386',
        mirror       => 'http://mirrors.wikimedia.org/debian',
        keyring      => '/usr/share/keyrings/debian-archive-keyring.gpg',
    }
    package_builder::pbuilder_base { 'sid-i386':
        distribution => 'sid',
        components   => 'main',
        architecture => 'i386',
        mirror       => 'http://mirrors.wikimedia.org/debian',
        keyring      => '/usr/share/keyrings/debian-archive-keyring.gpg',
    }

    # Wikimedia repos hooks
    # Note: sid does not have a wikimedia repo and will never do
    package_builder::pbuilder_hook { 'precise':
        distribution => 'precise',
        components   => 'main universe non-free thirdparty mariadb',
    }

    package_builder::pbuilder_hook { 'trusty':
        distribution => 'trusty',
        components   => 'main universe non-free thirdparty',
    }

    package_builder::pbuilder_hook { 'jessie':
        distribution => 'jessie',
        components   => 'main universe non-free thirdparty',
    }

    file { '/var/cache/pbuilder/hooks':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { '/etc/pbuilderrc':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('package_builder/pbuilderrc.erb'),
    }

    Package['cowbuilder'] -> File['/etc/pbuilderrc']
    File['/etc/pbuilderrc'] -> File['/var/cache/pbuilder/hooks']
    Package['cowbuilder'] -> Package_builder::Pbuilder_base['precise-amd64']
    Package['cowbuilder'] -> Package_builder::Pbuilder_base['trusty-amd64']
    Package['cowbuilder'] -> Package_builder::Pbuilder_base['jessie-amd64']
    Package['cowbuilder'] -> Package_builder::Pbuilder_base['sid-amd64']
    Package['cowbuilder'] -> Package_builder::Pbuilder_base['precise-i386']
    Package['cowbuilder'] -> Package_builder::Pbuilder_base['trusty-i386']
    Package['cowbuilder'] -> Package_builder::Pbuilder_base['jessie-i386']
    Package['cowbuilder'] -> Package_builder::Pbuilder_base['sid-i386']
    File['/var/cache/pbuilder/hooks'] -> Package_builder::Pbuilder_hook['precise']
    File['/var/cache/pbuilder/hooks'] -> Package_builder::Pbuilder_hook['trusty']
    File['/var/cache/pbuilder/hooks'] -> Package_builder::Pbuilder_hook['jessie']
}
