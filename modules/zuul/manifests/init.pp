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

    if os_version('debian jessie') {
        package { 'zuul':
            ensure => present,
        }
    } else {
        require_package('virtualenv', 'make')

        # Both merger and server require the zuul class
        if !defined(Scap::Target['zuul/deploy']) {
            scap::target { 'zuul/deploy':
                deploy_user => 'deploy-zuul',
            }
        }
    }

}
