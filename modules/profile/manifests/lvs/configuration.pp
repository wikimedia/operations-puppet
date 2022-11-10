# SPDX-License-Identifier: Apache-2.0
# @param class_hosts lvs host classification
class profile::lvs::configuration (
    Hash[
        Profile::Lvs::Classes,
        Profile::Lvs::Class_hosts
    ] $class_hosts = lookup('profile::lvs::configuration::class_hosts'),
) {

    # get the list of classes for this host
    $_host_class_hosts = $class_hosts.filter |$_, $hosts| {
        $facts['networking']['hostname'] in $hosts.values
    }
    # Ensure we have at least one classification
    if $_host_class_hosts.size == 0 {
        $lvs_class = 'unclassified'
        $primary = false
        $secondary = false
    } else {
        # Check if we are a primary
        $primary = $_host_class_hosts.any |$item| { $item[1]['primary'] == $facts['networking']['hostname'] }
        $secondary = $_host_class_hosts.any |$item| { $item[1]['secondary'] == $facts['networking']['hostname'] }
        if $primary and $secondary {
            fail('host is listed as both an lvs primary and secondary')
        }
        # If we are primary we only want to be primary for one class
        if $primary and $_host_class_hosts.size > 1 {
            fail('host is primary for more then one class')
        }
        # At this point we know that $_host_class_hosts has size 1 if the host is primary
        $lvs_class = $secondary.bool2str('secondary', $_host_class_hosts.keys[0])
        motd::message { "LVS Class: ${lvs_class}": }
    }
    # We create a motd which also allows us to use rspec to test

    # Create backwards compatible data structure
    # We create an empty hash of defaults as not all sites have a all keys specifcally low-traffic
    $default = {
        'high-traffic1' => [],
        'high-traffic2' => [],
        'low-traffic' => [],
    }
    $lvs_class_hosts = $default + Hash($class_hosts.map |$value| {
        [$value[0], $value[1].values]
    })
}
