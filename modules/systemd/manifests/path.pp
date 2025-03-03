# SPDX-License-Identifier: Apache-2.0
# == define systemd::path
#
# Sets up a systemd path, for path activated services, but not the
# associated service unit, which needs to be declared separately
# before this.
#
# === Parameters
# [*monitor_type*]
#   The monitor type as defined in systemd.path(5). Possible choices
#   are 'PathExists', 'PathExistsGlob', 'PathChanged', 'PathModified',
#   'DirectoryNotEmpty'
#
# [*ensure*]
#   Ensure the systemd path is present or not
#
# [*monitor_path*]
#   The unix path of the resource to be monitored. It depends on the value
#   of $monitor_type, as it can be a file path, a directory path or a file
#   glob.
#
# [*unit*]
#   The unit name of the service that needs to be (re)started after the
#   $monitor_type condition is satisfied.
#   If omitted the $title of this unit is used, otherwise a .service suffix
#   is appended (if not present).

define systemd::path(
    Systemd::Path::MonitorType $monitor_type,
    String $monitor_path,
    Wmflib::Ensure $ensure       = present,
    Systemd::Service::Name $unit = "${title}.service",
) {
    systemd::service { $title:
        ensure    => $ensure,
        unit_type => 'path',
        content   => template('systemd/systemd.path.erb'),
        require   => Systemd::Unit[$unit],
    }
}
