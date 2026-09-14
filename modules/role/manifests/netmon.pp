# SPDX-License-Identifier: Apache-2.0

class role::netmon {
    # Basic boilerplate for network-related servers
    require role::network::monitor

    # webserver for netmon servers
    include profile::netmon::httpd

    # common tools for netmon servers
    include profile::netmon::tools

    include profile::atlasexporter
    include profile::librenms
    include profile::rancid
    include profile::bgpalerter
    include profile::netmon::prober

    include profile::netmon::arelion_exporter
}
