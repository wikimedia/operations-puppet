# SPDX-License-Identifier: Apache-2.0
# @summary Defines a haproxy site configuration file managed by confd
# @param ensure Whether the file should exist or not
# @param content The content of the confd go template, as a string
# @param watch_keys List of keys to watch relative to the value assigned in $prefix
# @param prefix Prefix to use for all keys; it will actually be joined with the global confd prefix

define haproxy::confd_site (
    Wmflib::Ensure $ensure,
    String $content,
    Array[String[1]] $watch_keys,
    String $prefix = '',
) {
    $safe_title = regsubst($title, '[^a-zA-Z0-9]', '_', 'G')
    confd::file { "/etc/haproxy/conf.d/${safe_title}.cfg":
        ensure     => $ensure,
        content    => $content,
        watch_keys => $watch_keys,
        prefix     => $prefix,
        check      => '/usr/sbin/haproxy -c -V -f /etc/haproxy/haproxy.cfg -f',
        reload     => '/usr/bin/systemctl reload haproxy.service',
        before     => Service['haproxy'],
    }
}
