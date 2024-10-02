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
    ensure_packages(['ircstream'])
    file { '/etc/ircstream.conf':
        mode    => '0444',
        before  => Package['ircstream'],
        content => template('ircstream/ircstream.conf.erb'),
    }
}
