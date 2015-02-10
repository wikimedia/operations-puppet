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
# Is the usual metaparameter, defaults to true
#
#[*systemd*]
# Boolean - set it to true to make the resource include personalized
# init file. As this is used to You are expected to put them in a
# specific subdirectory of the current module, which is
# $module/initscripts/$name.systemd.erb for systemd  (and similarly for
# other init systems)
#
#[*upstart*]
# As the preceding param, but for upstart scripts
#
#[*sysvinit*]
# As the preceding param, but for traditional sysvinit scripts
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
#         ensure          => true,
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
    $service_params   = {},
    ) {

    validate_ensure($ensure)
    # Validates the service name, and picks the valid init script
    $initscript = pick_initscript(
        $::initsystem, $systemd, $upstart, $sysvinit)
    # we assume init scripts are templated
    if $initscript {
        if $caller_module_name {
            $template = "${caller_module_name}/initscripts/${name}.${initscript}.erb"
        }
        else {
            $template = "initscripts/${name}.${initscript}.erb"
        }
        $path = $initscript ? {
            'systemd'  => "/etc/systemd/system/${name}.service",
            'upstart'  => "/etc/init/${name}.conf",
            default    => "/etc/init.d/${name}"
        }

        file {$path:
            ensure  => $ensure,
            content => template($template),
            mode    => '0544',
            owner   => root,
            group   => root,
            notify  => Service[$name]
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

    $base_params = { ensure => ensure_service($ensure), provider => $::initsystem }
    $params = merge($base_params, $service_params)
    ensure_resource('service',$name, $params)
}
