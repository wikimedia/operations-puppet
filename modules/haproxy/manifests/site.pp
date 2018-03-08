# == Define: haproxy::site
#
# Provisions an Haproxy vhost. Like file resources, this resource type takes
# either a 'content' parameter with a string literal value or or 'source'
# parameter with a Puppet file reference. The resource title is used as the
# site name.
#
# === Parameters
#
# [*content*]
#   The Haproxy site configuration as a string literal.
#   Either this or 'source' must be set.
#
# [*source*]
#   The Haproxy site configuration as a Puppet file reference.
#   Either this or 'content' must be set.
#
# [*ensure*]
#   'present' or 'absent'; whether the site configuration is
#   installed or removed in sites-available/
#
# === Examples
#
#  haproxy::site { 'graphite':
#    content => template('graphite/graphite.nginx.erb'),
#  }
#
define haproxy::site(
    $ensure  = present,
    $content = undef,
    $source  = undef,
) {
    include ::haproxy

    $basename = regsubst($title, '[\W_]', '-', 'G')

    file { "/etc/haproxy/conf.d/${basename}.cfg":
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => $content,
        source  => $source,
        notify  => Exec['restart-haproxy'],
    }
}
