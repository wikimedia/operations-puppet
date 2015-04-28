# == Define: apache::static_site
#
# This resource allows you to provision simple static sites.
#
# === Parameters
#
# [*ensure*]
#   If 'present', site will be enabled; if 'absent', disabled.
#   The default is 'present'.
#
# [*docroot*]
#   Path to document root. It is assumed to exist and to be readable
#   by www-data.
#
# [*servername*]
#   The ServerName of the site. Defaults to the resource name.
#
# [*restricted_to*]
#   If defined, must be either a string LDAP group name or an array of
#   LDAP group names. Access will be limited to these groups. Undefined
#   by default.
#
# [*priority*]
#   If you need this site to load before or after other sites, you can
#   do so by manipulating this value. In most cases, the default value
#   of 50 should be fine.
#
# === Examples
#
#  apache::static_site { 'performance':
#    ensure        => present,
#    servername    => 'performance.wikimedia.org',
#    restricted_to => [ 'wmf', 'nda' ],
#  }
#
define apache::static_site(
    $docroot,
    $ensure        = present,
    $servername    = $name,
    $restricted_to = undef,
    $priority      = undef,
) {
    validate_ensure($ensure)
    validate_absolute_path($docroot)

    $ldap_groups     = any2array($restricted_to)
    $servername_safe = regsubst($servername, '[\W_]', '-', 'G')
    $servername_real = is_domain_name($servername) ? {
        true  => $servername,
        false => "${servername}.wikimedia.org",
    }

    include ::apache
    include ::apache::mod::headers
    include ::apache::mod::rewrite

    if ! empty($ldap_groups) {
        include ::apache::mod::authnz_ldap
        include ::passwords::ldap::production
    }

    ferm::service { "${servername_safe}_http":
        ensure => $ensure,
        proto  => 'tcp',
        port   => 80,
    }

    apache::site { $name:
        ensure    => $ensure,
        content   => template('apache/static.conf.erb'),
        conf_type => 'sites',
        priority  => $priority,
    }
}
