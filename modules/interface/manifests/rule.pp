# SPDX-License-Identifier: Apache-2.0
# @summary defines a routing policy rule
# @param interface interface to attach this rule to
# @param from match traffic coming from this address
# @param table use this table for traffic that matches the conditions
# @param ensure ensure
define interface::rule (
    String[1]           $interface,
    Stdlib::IP::Address $from,
    Wmflib::Ensure      $ensure = 'present',
    Optional[String[1]] $table  = undef,
) {
    $from_cidr = wmflib::ip2cidr($from)
    $version = $from_cidr ? {
        Stdlib::IP::Address::V6 => ' -6',
        default                 => '',
    }

    $from_cmd = " from ${$from_cidr}"

    $table_cmd = $table.then |$t| { " table ${t}" }
    $table_require = $table.then |$t| { Interface::Routing_table[$t] }

    $command = "ip${version} rule add${from_cmd}${table_cmd}"

    interface::post_up_command { $title:
        ensure    => $ensure,
        command   => $command,
        interface => $interface,
        require   => $table_require,
    }
}
