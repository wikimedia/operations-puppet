# == Base::service_unit ==
#
# Allows defining services and their corresponding init scripts in a
# init-system agnostic way on Debian derivatives.
#
# We prefer convention over configuration, so this define will require
# you to respect those in order to work.
#
# === Parameters ===
#
#[*ensure*]
# Is the usual metaparameter, defaults to present
#
#[*template_name*]
# String, default $name.  Init file template pathnames are formed
# using the pattern "$module/initscripts/$template_name.$initsystem.erb"
#
#[*systemd*]
# Boolean - set it to true to make the resource include personalized
# init file. As this is used to You are expected to put them in a
# specific subdirectory of the current module, which is
# $module/initscripts/$template_name.systemd.erb for systemd  (and
# similarly for other init systems)
#
#[*upstart*]
# As the preceding param, but for upstart scripts
#
#[*sysvinit*]
# As the preceding param, but for traditional sysvinit scripts
#
#[*strict*]
# Boolean - if true (default), only allows to have customized scripts
# for all init systems; if false allows to use standard scripts from
# the distro (e.g. memcached will need a custom systemd unit, but use
# the standard init file on upstart).
#
#[*refresh*]
# Boolean - tells puppet if a change in the config should notify the service directly
#
#[*service_params*]
# An hash of parameters that we want to apply to the service resource
#
# === Example ===
#
# A init-agnostic class that runs apache, with its own init scripts
# (please, don't do it at home!)
#
# class foo {
#     base::service_unit { 'apache2':
#         ensure          => present,
#         sysvinit        => true,
#         service_params  => {
#             hasrestart => true,
#             restart => '/usr/sbin/service apache2 restart'
#         }
#     }
# }
define base::service_unit (
    $ensure           = present,
    $systemd          = false,
    $upstart          = false,
    $sysvinit         = false,
    $strict           = true,
    $refresh          = true,
    $template_name    = $name,
    $service_params   = {},
    ) {

    validate_ensure($ensure)
    # Validates the service name, and picks the valid init script
    $initscript = pick_initscript(
        $::initsystem, $systemd, $upstart, $sysvinit, $strict)
    # we assume init scripts are templated
    if $initscript {
        if $caller_module_name {
            $template = "${caller_module_name}/initscripts/${template_name}.${initscript}.erb"
        }
        else {
            $template = "initscripts/${template_name}.${initscript}.erb"
        }
        $path = $initscript ? {
            'systemd'  => "/etc/systemd/system/${name}.service",
            'upstart'  => "/etc/init/${name}.conf",
            default    => "/etc/init.d/${name}"
        }

        # systemd complains if unit files are executable
        if $initscript == 'systemd' {
            $i_mode = '0444'
        } else {
            $i_mode = '0544'
        }

        file {$path:
            ensure  => $ensure,
            content => template($template),
            mode    => $i_mode,
            owner   => root,
            group   => root,
        }

        if $refresh {
            File[$path] ~> Service[$name]
        } else {
            File[$path] -> Service[$name]
        }

        if $::initsystem == 'systemd' {
                exec { "systemd reload for ${name}":
                    refreshonly => true,
                    command     => '/bin/systemctl daemon-reload',
                    subscribe   => File[$path],
                    before      => Service[$name]
                }

        }
    }

    $base_params = {
        ensure => ensure_service($ensure),
        provider => $::initsystem }
    $params = merge($base_params, $service_params)
    ensure_resource('service',$name, $params)
}
