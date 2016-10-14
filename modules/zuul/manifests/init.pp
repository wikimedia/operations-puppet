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

    package { 'zuul':
        ensure => present,
    }

}
