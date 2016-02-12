# == Class: role::simplestatic
# Role that takes a list of hostnames and a basepath
# and sets up Apache to serve a static site from
# each basepath/hostname location.

class role::simplestatic (
    $host_names = [],
    $base_path = '/srv',
) {
    # This role is expected to be used only in labs
    requires_realm('labs')

    include ::apache::mod::rewrite
    include ::apache::mod::headers

    apache::site { 'simplestatic':
        ensure  => present,
        content => template('apache/sites/simplestatic.erb'),
    }
}
