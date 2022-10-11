# SPDX-License-Identifier: Apache-2.0
# @summary helper resource to create systemd service overrides
# @param unit the name of the service to override
# @param content the content of the systemd unit file
# @param ensure the ensurable parameter
# @param restart if true restart the service when the override file changes
define systemd::override (
    String[1]      $unit,
    String[1]      $content,
    Wmflib::Ensure $ensure  = present,
    Boolean        $restart = false,
) {
    systemd::unit { "${unit}-${title}":
        override_filename => $title,
        *                 => wmflib::dump_params(),
    }
}
