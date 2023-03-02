# SPDX-License-Identifier: Apache-2.0
# Class: profile::ceph::osds
#
# This profile configures hosts with the Ceph osds daemon
class profile::ceph::osds (
    Hash[String,Hash]       $mon_hosts                 = lookup('profile::ceph::mon::hosts'),
    Hash[String,Hash]       $osd_hosts                 = lookup('profile::ceph::osd::hosts'),
    Boolean                 $discrete_bluestore_device = lookup('profile::ceph::osd::discrete_bluestore_device', { 'default_value' => false }),
    String                  $fsid                      = lookup('profile::ceph::fsid'),
    Optional[Array[String]] $absent_osds               = lookup('profile::ceph::osd::absent_osds', { 'default_value' => undef }),
    Optional[Array[String]] $excluded_slots            = lookup('profile::ceph::osd::excluded_slots', { 'default_value' => undef }),
    Optional[String]        $bluestore_device_name     = lookup('profile::ceph::osd::bluestore_device_name', { 'default_value' => undef }),
    ) {
    # Ceph OSDs should use the performance governor, not the default 'powersave'
    # governor
    class { 'cpufrequtils': }

    require profile::ceph::auth::load_all

    require profile::ceph::server::firewall

    require profile::ceph::core

    class { 'ceph::osds':
        fsid                      => $fsid,
        mon_hosts                 => $mon_hosts,
        osd_hosts                 => $osd_hosts,
        absent_osds               => $absent_osds,
        excluded_slots            => $excluded_slots,
        discrete_bluestore_device => $discrete_bluestore_device,
        bluestore_device_name     => $bluestore_device_name,
    }
}
