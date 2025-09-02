# SPDX-License-Identifier: Apache-2.0
# @summary defines a routing table name
# @param number numeric identifier of this routing table
# @param ensure ensure
define interface::routing_table (
    Integer[1, 252] $number,
    Wmflib::Ensure  $ensure = 'present',
) {

    # This directory is no longer shipped by iproute2 on >= Trixie
    wmflib::dir::mkdir_p('/etc/iproute2/rt_tables.d')

    file { "/etc/iproute2/rt_tables.d/${title}.conf":
        ensure  => stdlib::ensure($ensure, 'file'),
        content => "${number} ${title}\n",
    }
}
