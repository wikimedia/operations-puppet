# == Class maven
# Install maven and sets it up with default mirroring to
# archiva.wikimedia.org
class maven {
    if !defined(Package['maven']) {
        package { 'maven':
            ensure => present,
        }
    }

    file { '/etc/maven/settings.xml':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/maven/settings.xml',
        require => Package['maven'],
    }
}
