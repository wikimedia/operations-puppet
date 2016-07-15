# OpenStack zuul
#
# A Jenkins/Gerrit gateway written in python. This is a drop in replacement
# for Jenkins "Gerrit Trigger" plugin.
#
# == Class: zuul
#
# Install Zuul
#
class zuul ( ){

    include zuul::user

    # Pin python-pbr to an old version for Zuul

    # Zuul has a version string that isn't SemVer compliant.
    # Ideally we should rebuild Zuul with a new version string,
    # but for now this will do.
    if os_version('debian == jessie') {
        include ::apt
        apt::pin { 'python-pbr':
            pin      => 'release o=debian',
            priority => '1002',
            before   => Package['zuul'],
        }
    }


    package { 'zuul':
        ensure => present,
    }

}
