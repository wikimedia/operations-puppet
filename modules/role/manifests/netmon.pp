# SPDX-License-Identifier: Apache-2.0

class role::netmon {

    system::role { 'netmon':
        description => 'Network monitoring and management'
    }

    # Basic boilerplate for network-related servers
    require ::role::network::monitor

    # webserver for netmon servers
    include ::profile::netmon::httpd

    # common tools for netmon servers
    include ::profile::netmon::tools

    include ::profile::atlasexporter
    include ::profile::librenms
    include ::profile::rancid
    include ::profile::smokeping
    include profile::netmon::prober
}
