# == Define: httpd::conf
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
#   Either 'sites' for a vhost config, 'conf' for instance-wide configs,
#   or 'env' for envvars. The default is 'conf'.
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
# [*replaces*]
#   A relative path to a file that is superseded by this one. Can be
#   useful when redefining module configurations in ways incompatible
#   with what shipped by the distribution. If the path is not empty,
#   this will ensure the removal of the replaced file.
#
# === Examples
#
#  httpd::conf { 'blog.wikimedia.org':
#    ensure  => present,
#    content => template('blog/blog-apache-config.erb'),
#  }
#
define httpd::conf(
    Wmflib::Ensure $ensure = present,
    Enum['conf', 'env', 'sites'] $conf_type = 'conf',
    Integer[0, 99] $priority  = 50,
    Optional[String] $content   = undef,
    Wmflib::Sourceurl $source    = undef,
    Optional[String] $replaces  = undef,
) {
    require_package('apache2')
    if $source == undef and $content == undef and $ensure == 'present' {
        fail('you must provide either "source" or "content", or ensure must be "absent"')
    }
    if $source != undef and $content != undef  {
        fail('"source" and "content" are mutually exclusive')
    }

    $title_safe  = regsubst($title, '[\W_]', '-', 'G')
    $file_ext    = $conf_type ? { 'env' => 'sh', default => 'conf' }
    $conf_file   = sprintf('%02d-%s.%s', $priority, $title_safe, $file_ext)
    $content_formatted = $content ? {
        undef   => undef,
        default => regsubst($content, "\n?$", "\n"),
    }

    file { "/etc/apache2/${conf_type}-available/${conf_file}":
        ensure  => $ensure,
        content => $content_formatted,
        source  => $source,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['apache2'],
    }

    file { "/etc/apache2/${conf_type}-enabled/${conf_file}":
        ensure => ensure_link($ensure),
        target => "/etc/apache2/${conf_type}-available/${conf_file}",
        notify => Service['apache2'],
    }

    if $replaces != undef {
        file { "${title_safe}_${replaces}":
            ensure => absent,
            path   => "/etc/apache2/${replaces}",
        }
    }
}
