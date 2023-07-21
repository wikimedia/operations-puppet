# SPDX-License-Identifier: Apache-2.0
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
# [*instance*] Which confd::instance we should configure. Anything other than the
#              default 'main' instance will need to be instantiated explicitly
#
# [*watch_keys*] list of keys to watch relative to the value assigned in
#                $prefix
#
# [*uid*] Numeric uid of the owner of the file produced. Default: 0
#
# [*gid*] Numeric gid of the owner of the produced file. Default: 0
#
# [*mode*] File mode for the generated file
#
# [*reload*] Command to execute when the produced file changes
#
# [*check*] Check to execute when the produced file changes
#
# [*content*] The actual go text/template used for generating the file
#
# [*relative_prefix*] if true prepend the global prefix configured in the confd class
#
define confd::file (
    $ensure     = 'present',
    $prefix     = undef,
    $instance   = 'main',
    $watch_keys = [],
    $uid        = undef,
    $gid        = undef,
    $mode       = '0444',
    $reload     = undef,
    $check      = undef,
    $content    = undef,
    Boolean $relative_prefix = true,
) {

    if $instance == 'main' {
        # On the main instance, we don't define $prefix
        # globally from the command line, but instead we prepend it
        # to the single templates.
        # This is done for historical reasons - we did this to allow multiple
        # definitions which would use different prefixes, but it's a hack.
        # TODO: use multiple instances instead of this hack.
        include confd::default_instance
        $confd_prefix = $confd::default_instance::prefix
    } else {
        $confd_prefix = ''
    }

    $label = $instance ? {
        'main'  => 'confd',
        default => sprintf('confd-%s', regsubst($instance, '/', '_', 'G')),
    }
    $path = "/etc/${label}"

    $_prefix = $relative_prefix.bool2str("${confd_prefix}${prefix}", $prefix)
    $safe_name = regsubst($name, '/', '_', 'G')

    file { "${path}/templates/${safe_name}.tmpl":
        ensure  => $ensure,
        mode    => '0400',
        content => $content,
        require => Package['confd'],
        before  => File["${path}/conf.d/${safe_name}.toml"],
    }

    #TODO validate at least uid and guid
    file { "${path}/conf.d/${safe_name}.toml":
        ensure  => $ensure,
        content => template('confd/service_template.toml.erb'),
        notify  => Service[$label],
    }

    if $ensure == 'absent' {
        file { $name:
            ensure => 'absent',
        }
    }
}
