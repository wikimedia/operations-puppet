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
    $content    = undef,
) {

    include ::confd

    $safe_name = regsubst($name, '/', '_', 'G')

    file { "/etc/confd/templates/${safe_name}.tmpl":
        ensure  => $ensure,
        mode    => '0400',
        content => $content,
        require => Package['confd'],
        before  => File["/etc/confd/conf.d/${safe_name}.toml"],
    }

    #TODO validate at least uid and guid
    file { "/etc/confd/conf.d/${safe_name}.toml":
        ensure  => $ensure,
        content => template('confd/service_template.toml.erb'),
        notify  => Service['confd'],
    }

    # In particular situations, we might not want monitoring
    if $::confd::monitor_files {
        nrpe::monitor_service{ "confd${safe_name}":
            description  => "Confd template for ${name}",
            nrpe_command => "/usr/local/lib/nagios/plugins/check_confd_template '${name}'",
            require      => File['/usr/local/lib/nagios/plugins/check_confd_template'],
        }
    }
}
