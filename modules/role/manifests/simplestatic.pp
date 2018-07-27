# == Class: role::simplestatic
# Role that takes a list of hostnames and a basepath
# and sets up Apache to serve a static site from
# each basepath/hostname location.
#
# filtertags: labs-project-dashiki

class role::simplestatic (
    $host_names = [],
    $base_path = '/srv',
) {
    # This role is expected to be used only in labs
    requires_realm('labs')

    class { '::httpd':
        modules => ['rewrite', 'headers'],
    }

    httpd::site { 'simplestatic':
        ensure  => present,
        content => template('role/apache/sites/simplestatic.erb'),
    }
}
