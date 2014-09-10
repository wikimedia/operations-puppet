# == Class pybal::web
#
# Sets up the virtualhost and the other resources for serving the pybal configs.
#
# == Parameters
#
# [*chostname*]
# The ServerAlias hostname to add to the virtual host.
#

class pybal::web ($ensure = 'present', $vhostnames = ['pybal-config.eqiad.wmnet']) {

    include wmflib

    $is_24 = ubuntu_version('>= trusty')

    apache::site { 'pybal-config':
        ensure   => $ensure,
        priority => 50,
        content  => template('pybal/config-vhost.conf.erb'),
        notify   => Service['apache2'],
        require  => File['/srv/pybal-config'],
    }

    file { '/srv/pybal-config':
        ensure => ensure_directory($ensure),
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

}
