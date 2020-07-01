# == Class maven
# Install maven and sets it up with default mirroring to
# archiva.wikimedia.org
class maven {
    if !defined(Package['maven']) {
        package { 'maven':
            ensure => present,
        }
    }

    # Install ivysettings uses archiva.wikimedia.org repositories to resolve dependencies.
    # This can be used with spark jobs to resolve dependencies at runtime.
    # While perhaps 'ivy' things don't belong in a WMF maven model, this is the easiest
    # place to store this information.
    # See: https://phabricator.wikimedia.org/T216093
    file { '/etc/maven/ivysettings.xml':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/maven/ivysettings.xml',
        require => Package['maven'],
    }
}
