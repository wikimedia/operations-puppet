# == Define confd::file
#
# Defines a service template to be monitored by confd,
# and the corresponding geneated config file.

define confd::file (
    $ensure     = 'present',
    $watch_keys = [],
    $uid        = undef,
    $gid        = undef,
    $mode       = '0444',
    $reload     = undef,
    $check      = undef,
    $tmpl       = undef,
) {

    $safe_name = regsubst($name, '/', '_', 'G')

    #TODO validate at least uid and guid
    file { "/etc/confd/conf.d/${safe_name}.toml":
        ensure  => $ensure,
        content => template('confd/service_template.toml.erb'),
    }

    file { "/etc/confd/templates/${safe_name}.tmpl":
        ensure  => $ensure,
        mode    => '0400',
        content => template($tmpl),
        notify  => Service['confd'],
    }
}
