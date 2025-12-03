# SPDX-License-Identifier: Apache-2.0
# @summary Cloud VPS metadata web server
class profile::wmcs::cloudvps_meta (
    Stdlib::Fqdn $host = lookup('profile::wmcs::cloudvps_meta::host', {default_value => 'meta.wmcloud.org'}),
) {
    $base_path = "/srv/${host}"

    file { $base_path:
        ensure  => directory,
        owner   => 'root',
        group   => 'www-data',
        recurse => true,
        purge   => true,
        force   => true,
    }

    class { 'httpd': }

    httpd::site { $host:
        content => template('profile/wmcs/cloudvps_meta/apache.conf.erb'),
    }
}
