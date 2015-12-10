# == Class: role::apache::static_multihost
# Role that takes a list of hostnames and a basepath
# and sets up Apache to serve a static site from 
# basepath/hostname.

class role::apache_static_multihost {

    $host_names = hiera('host_names', [])
    $base_path = hiera('base_path', '/srv')

    apache::site { 'static-multihost':
        ensure  => present,
        content => template('apache/static_multihost.erb'),
    }
}
