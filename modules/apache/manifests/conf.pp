# == Define: apache::conf
#
# Manages Apache configuration snippets. This is a very thin wrapper around
# a File resource for a /etc/apache2/{conf,sites}-available config file and a
# symlink pointing to it in /etc/apache/{conf,sites}-enabled. By using it, you
# don't have to worry about dependencies and ordering; the resource will
# take care that Apache & all modules are provisioned before the conf is.
#
# === Parameters
#
# [*ensure*]
#   If 'present', config will be enabled; if 'absent', disabled.
#   The default is 'present'.
#
# [*conf_type*]
#   Either 'sites' for a vhost config or 'conf' for instance-wide configs.
#   The default is 'conf'.
#
# [*priority*]
#   If you need this config to load before or after other configs, you can
#   do so by manipulating this value. In most cases, the default value
#   of 50 should be fine.
#
# [*content*]
#   If defined, will be used as the content of the configuration
#   file. Undefined by default. Mutually exclusive with 'source'.
#
# [*source*]
#   Path to file containing configuration directives. Undefined by
#   default. Mutually exclusive with 'content'.
#
# === Examples
#
#  apache::conf { 'blog.wikimedia.org':
#    ensure  => present,
#    content => template('blog/blog-apache-config.erb'),
#  }
#
define apache::conf(
    $ensure    = present,
    $conf_type = 'conf',
    $priority  = 50,
    $content   = undef,
    $source    = undef,
) {
    include ::apache

    if $priority  !~ /^\d?\d$/                 { fail('"priority" must be between 0 - 99')             }
    if $ensure    !~ /^(present|absent)$/      { fail('"ensure" must be "present" or "absent"')        }
    if $conf_type !~ /^(conf|sites)$/          { fail('"conf_type" must be "conf" or "sites"')         }
    if $source == undef and $content == undef  { fail('you must provide either "source" or "content"') }
    if $source != undef and $content != undef  { fail('"source" and "content" are mutually exclusive') }

    $title_safe  = regsubst($title, '[\W_]', '-', 'G')
    $conf_file   = sprintf('%02d-%s.conf', $priority, $title_safe)
    $link_ensure = $ensure ? {
        present => link,
        default => absent,
    }

    file { "/etc/apache2/${conf_type}-available/${conf_file}":
        ensure  => $ensure,
        content => $content,
        source  => $source,
    }

    file { "/etc/apache2/${conf_type}-enabled/${conf_file}":
        ensure  => $link_ensure,
        target  => "/etc/apache2/${conf_type}-available/${conf_file}",
        notify  => Service['apache2'],
    }
}
