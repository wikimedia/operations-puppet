# == Class: role::apache::static_multihost
# Role that takes a list of hostnames and a basepath
# and sets up Apache to serve a static site from 
# basepath/hostname.

class role::apache::static_multihost(
    $host_names = [],
    $base_path  = '/srv'
) {
    apache::site { 'static-multihost':
       ensure  => present,
       content => template('apache/static_multihost.erb'),
    }
}
