# SPDX-License-Identifier: Apache-2.0
# == Define: nginx::site
#
# Provisions an Nginx vhost. Like file resources, this resource type takes
# either a 'content' parameter with a string literal value or 'source'
# parameter with a Puppet file reference. The resource title is used as the
# site name.
#
# === Parameters
#
# [*content*]
#   The Nginx site configuration as a string literal.
#   Either this or 'source' must be set.
#
# [*source*]
#   The Nginx site configuration as a Puppet file reference.
#   Either this or 'content' must be set.
#
# [*ensure*]
#   'present' or 'absent'; whether the site configuration is
#   installed or removed in sites-available/
#
# === Examples
#
#  nginx::site { 'graphite':
#    content => template('graphite/graphite.nginx.erb'),
#  }
#
define nginx::site(
    Wmflib::Ensure               $ensure  = 'present',
    Optional[String]             $content = undef,
    Optional[Stdlib::Filesource] $source  = undef,
){

    include nginx

    $basename = regsubst($title, '[\W_]', '-', 'G')

    file { "/etc/nginx/sites-available/${basename}":
        ensure  => $ensure,
        content => $content,
        source  => $source,
        tag     => 'nginx', # workaround PUP-2689, can remove w/ puppetmaster 3.6.2+
        notify  => Exec['nginx-reload'],
    }

    file { "/etc/nginx/sites-enabled/${basename}":
        ensure => stdlib::ensure($ensure, 'link'),
        target => "/etc/nginx/sites-available/${basename}",
        tag    => 'nginx', # workaround PUP-2689, can remove w/ puppetmaster 3.6.2+
    }
}
