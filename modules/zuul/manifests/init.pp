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

    if os_version('debian == jessie') {
        apt::pin { 'python-pbr':
            pin      => 'release a=jessie-main',
            priority => '1002',
            before   => Package['zuul'],
        }
    }


    package { 'zuul':
        ensure => present,
    }

}
