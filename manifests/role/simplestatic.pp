# == Class: role::simplestatic
# Role that takes a list of hostnames and a basepath
# and sets up Apache to serve a static site from
# each basepath/hostname location.

class role::simplestatic (
    $host_names = [],
    $base_path = '/srv',
) {

    apache::site { 'simplestatic':
        ensure  => present,
        content => template('apache/sites/simplestatic.erb'),
    }
}
