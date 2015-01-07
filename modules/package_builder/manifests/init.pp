class package_builder(
    $version='trusty',
    $components='main universe',
) {
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
        ]:
        ensure => present,
    }

    exec { 'cowbuilder_init':
        command => "/usr/sbin/cowbuilder --create --components \"${components}\"",
        creates => '/var/cache/pbuilder/base.cow',
    }

    file { '/var/cache/pbuilder/hooks':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { '/var/cache/pbuilder/hooks/D01apt.wikimedia.org':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        content => template('package_builder/D01.apt.wikimedia.org.erb'),
    }
}
