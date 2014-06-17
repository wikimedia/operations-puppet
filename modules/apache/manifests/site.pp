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
) {
    include ::apache

    if $priority !~ /^\d?\d$/             { fail('"priority" must be between 0 - 99')      }
    if $ensure   !~ /^(present|absent)$/  { fail('"ensure" must be "present" or "absent"') }

    $title_safe  = regsubst($title, '[\W_]', '-', 'G')
    $config_file = sprintf('%02d-%s.conf', $priority, $title_safe)
    $link_ensure = $ensure ? {
        present => link,
        default => absent,
    }

    file { "/etc/apache2/sites-available/${config_file}":
        ensure  => $ensure,
        content => $content,
        source  => $source,
        require => Package['apache2'],
    }

    file { "/etc/apache2/sites-enabled/${config_file}":
        ensure  => $link_ensure,
        target  => "/etc/apache2/sites-available/${config_file}",
        require => Package['apache2'],
        notify  => Service['apache2'],
    }
}
