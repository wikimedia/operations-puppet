# == Define confd::file
#
# Defines a service template to be monitored by confd,
# and the corresponding geneated config file.
#
# === Parameters
#
# [*prefix*] Prefix to use for all keys; it will actually be joined with the global
#            confd prefix
#
# [*watch_keys*] list of keys to watch relative to the value assigned in
#                $prefix.
#
# [*uid*] Numeric uid of the owner of the file produced. Default: 0
#
# [*gid*] Numeric gid of the owner of the produced file. Default: 0
#
# [*mode*] File mode for the generated file.
#
# [*reload*] Command to execute when the produced file changes
#
# [*check*] Check to execute when the produced file changes
#
# [*content*] The actual go text/template used for generating the file
#
define confd::file (
    $ensure     = 'present',
    $prefix     = undef,
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
            notes_url    => 'https://wikitech.wikimedia.org/wiki/Confd',
        }
    }
}
