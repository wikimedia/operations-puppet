# SPDX-License-Identifier: Apache-2.0
# @summary Converts from abstract quality of service class name to DSCP value
# Valid inputs are mgmt/high/low, and return values are the corresponding
# DSCP values used on the core network to represent traffic belonging to these
# classes.
function firewall::qos2dscp(
    Firewall::Qos $qos,
) >> String {
    $qos ? {
        'control' => 'cs6',
        'high'    => 'af21',
        'normal'  => 'cs0',
        'low'     => 'af41',
    }
}
