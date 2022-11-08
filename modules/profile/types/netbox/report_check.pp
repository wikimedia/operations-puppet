# SPDX-License-Identifier: Apache-2.0
type Profile::Netbox::Report_check = Struct[{
    'name'           => String[1],
    'class'          => String[1],
    'alert'          => Boolean,
    'check_interval' => Integer[1],
    # TODO: i think we have a systemd type for this
    'run_interval'   => String[1],
}]
