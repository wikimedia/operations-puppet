# SPDX-License-Identifier: Apache-2.0
# @summary Class to configure ircstream.
class profile::ircstream(
    Boolean     $use_eventstream = lookup('profile::ircstream::use_eventstream'),
){
    class { 'ircstream':
        eventstream => $use_eventstream,
    }

    # Allow users to connect with IRC.
    firewall::service { 'irc_public':
        proto => 'tcp',
        port  => 6667,
    }

    unless $use_eventstream {
        # Accept traffic from the mediawiki servers.
        # Mediawiki sends changes as a UDP data package.
        firewall::service { 'mediawiki_udp_data_packages':
            proto    => 'udp',
            port     => 9390,
            src_sets => ['MW_APPSERVER_NETWORKS']
        }
    }
}
