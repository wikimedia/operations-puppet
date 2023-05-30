# SPDX-License-Identifier: Apache-2.0
# For a given LVS server, return an array of IP addresses for all applicable
# instrumentation IPs.  This is meant to be called in the puppetization of
# actual pybal LVS servers, and relies on $::hostname, etc being that of the
# LVS server we need IPs for.
function wmflib::service::get_i13n_ips_for_lvs() >> Array[Stdlib::IP::Address] {
    if !defined(Class['profile::lvs::configuration']) {
        fail('wmflib::service::get_i13n_ips_for_lvs() requires profile::lvs::configuration to be included in your class explicitly')
    }
    $profile::lvs::configuration::lvs_class_hosts.filter |$class, $data| {
        $::hostname in $data
    }
    .keys.map |$class| {
        ipresolve(wmflib::service::get_i13n_for_lvs_class($class, $::site), 4)
    }
    .sort
}
