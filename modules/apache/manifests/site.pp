# == Define: apache::site
#
# Manages Apache site configurations. This is a very thin wrapper around
# a File resource for a /etc/apache2/sites-available config file and a
# symlink pointing to it in /etc/apache/sites-enabled. By using it, you
# don't have to worry about dependencies and ordering; the resource will
# take care that Apache & all modules are provisioned before the site is.
#
# === Parameters
#
# [*ensure*]
#   If 'present', site will be enabled; if 'absent', disabled.
#   The default is 'present'.
#
# [*priority*]
#   If you need this site to load before or after other sites, you can
#   do so by manipulating this value. In most cases, the default value
#   of 50 should be fine.
#
# [*content*]
#   If defined, will be used as the content of the site configuration
#   file. Undefined by default. Mutually exclusive with 'source'.
#
# [*source*]
#   Path to file containing configuration directives. Undefined by
#   default. Mutually exclusive with 'content'.
#
# [*ports*]
#   Configures how the file NameVirtualHost config and /etc/apache/ports.conf
#   is handled on this host. There are 3 options: 'distro', 'both' or 'none'.
#   'distro' means the file will not be handled by puppet and you get the default
#   ports.conf from the distro package. This is default. 'both' means that puppet
#   will handle the file and both a NameVirtualHost *:80 and a NameVirtualHost *:443
#   will be added and your individual site configs should _not_ repeat them.
#   'none' means that puppet will handle the file but no NameVirtualHosts will be added,
#   in this case your site configs _should_ have them instead.
#
# === Examples
#
#  apache::site { 'blog.wikimedia.org':
#    ensure  => present,
#    content => template('blog/blog-apache-config.erb'),
#  }
#
define apache::site(
    $ensure   = present,
    $priority = 50,
    $content  = undef,
    $source   = undef,
    $ports    = 'distro',
) {
    include ::apache

    apache::conf { $name:
        ensure    => $ensure,
        conf_type => 'sites',
        priority  => $priority,
        content   => $content,
        source    => $source,
    }
}
