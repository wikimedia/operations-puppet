#SPDX-License-Identifier: Apache-2.0
#@summary Class to install ircstream a mediawiki to IRC streaming service. See: https://github.com/paravoid/ircstream
class ircstream (
    Stdlib::Host $irc_listen_address = '::',
    Stdlib::Port $irc_listen_port = 6667,
    String       $irc_servername = 'irc.wikimedia.org',
    Stdlib::Host $rc2udp_listen_address = '::',
    Stdlib::Port $rc2udp_listen_port = 9390,
    Stdlib::Host $prometheus_listen_address = '::',
    Stdlib::Port $prometheus_listen_port = 16667,
    Boolean      $eventstream = false,
){
    if $eventstream {
        ensure_packages(['python3-aiohttp'])
        apt::package_from_component { 'ircstream':
            packages  => ['ircstream'],
            component => 'component/ircstream-sse',
            priority  => 1002,
        }
    } else {
        ensure_packages(['ircstream'])
    }

    $epp_params = {
        irc_listen_address        => $irc_listen_address,
        irc_listen_port           => $irc_listen_port,
        irc_servername            => $irc_servername,
        rc2udp_listen_address     => $rc2udp_listen_address,
        rc2udp_listen_port        => $rc2udp_listen_port,
        prometheus_listen_address => $prometheus_listen_address,
        prometheus_listen_port    => $prometheus_listen_port,
        eventstream               => $eventstream,
    }

    file { '/etc/ircstream.conf':
        mode    => '0444',
        before  => Package['ircstream'],
        content => epp('ircstream/ircstream.conf.epp', $epp_params),
    }
}
