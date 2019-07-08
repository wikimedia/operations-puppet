# == Define: nginx::snippet
#
# Provisions an Nginx snippet. Like file resources, this resource type takes
# either a 'content' parameter with a string literal value or or 'source'
# parameter with a Puppet file reference. The resource title is used as the
# snippet name.
#
# === Parameters
#
# [*content*]
#   The Nginx snippet configuration as a string literal.
#   Either this or 'source' must be set.
#
# [*source*]
#   The Nginx snippet configuration as a Puppet file reference.
#   Either this or 'content' must be set.
#
# [*ensure*]
#   'present' or 'absent'; whether the site configuration is
#   installed or removed in snippets/
#
# === Examples
#
#  nginx::snippet { 'csp_header':
#    content => template('graphite/csp.nginx.erb'),
#  }
#
# And then in an Nginx vhost include it with:
# include /etc/nginx/snippets/csp_header.conf;
#
define nginx::snippet(
    Wmflib::Ensure $ensure = present,
    Optional[String] $content = undef,
    Optional[Wmflib::Sourceurl] $source = undef,
) {
    include ::nginx

    file { "/etc/nginx/snippets/${title}.conf":
        ensure  => $ensure,
        content => $content,
        source  => $source,
        mode    => '0440',
        notify  => Exec['nginx-reload'],
    }
}

