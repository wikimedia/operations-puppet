# == systemd::unit ==
#
# This define creates a file on the filesystem at $path,
# schedules a daemon-reload of systemd and, if requested,
# schedules a subsequent refresh of the service.
#
# === Parameters ===
# The resource title is assumed to be the corresponding full unit
# name. If no valid unit suffix is present, 'service' will be assumed.
#
# [*content*]
#   The content of the file. Required.
# [*ensure*]
#   The usual meta-parameter, defaults to present. Valid values are
#   'absent' and 'present'
# [*restart*]
#   Whether to handle restarting the service when the file changes.
# [*override*]
#   If the are creating an override to system-provided units or not.
#   Defaults to false
# [*override_filename*]
#   When creating an override, filename to use for the override. The given
#   filename would have the `.conf` extension added if missing.
#   Defaults to undef (use `puppet-override.conf`)
#
# === Examples ===
#
# A systemd override for the hhvm.service unit
#
# systemd::unit { 'hhvm':
#     ensure   => present,
#     content  => template('hhvm/initscripts/hhvm.systemd.erb'),
#     restart  => false,
#     override => true,
# }
#
# # A socket for nginx
# systemd::unit { 'nginx.socket':
#     ensure   => present,
#     content  => template('nginx/nginx.socket.erb'),
#     restart  => true, # This will work only if you have service{ `nginx.socket`: }
# }
#
define systemd::unit(
    String $content,
    Wmflib::Ensure $ensure=present,
    Boolean $restart=false,
    Boolean $override=false,
    Optional[String[1]] $override_filename=undef,
){
    require ::systemd

    if ($title =~ /^(.+)\.(\w+)$/ and $2 =~ Systemd::Unit_type){
        $unit_name = $title
    } else {
        $unit_name = "${title}.service"
    }

    if ($override) {
        # Define the override dir if not defined.
        $override_dir = "${::systemd::override_dir}/${unit_name}.d"
        file { $override_dir:
            ensure => stdlib::ensure($ensure, 'directory'),
            owner  => 'root',
            group  => 'root',
            mode   => '0555',
        }

        $path = $override_filename ? {
            undef     => "${override_dir}/puppet-override.conf",
            /\.conf$/ => "${override_dir}/${override_filename}",
            default   => "${override_dir}/${override_filename}.conf",
        }
    } else {
        $path = "${::systemd::base_dir}/${unit_name}"
    }

    $exec_label = "systemd daemon-reload for ${unit_name}"
    file { $path:
        ensure  => $ensure,
        content => $content,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        notify  => Exec[$exec_label],
    }

    exec { $exec_label:
        refreshonly => true,
        command     => '/bin/systemctl daemon-reload',
    }

    # If the service is defined, add a dependency.

    if defined(Service[$title]) {
        if $ensure == 'present' {
            # systemd must reload units before the service is managed
            if $restart {
                # Refresh the service if restarts are required
                Exec[$exec_label] ~> Service[$title]
            } else {
                Exec[$exec_label] -> Service[$title]
            }
        } else {
            # the service should be managed before the daemon-reload
            Service[$title] -> Exec[$exec_label]
        }
    }
}
