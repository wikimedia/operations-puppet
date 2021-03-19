# Class profile::rsyslog::udp_tee - udp_tee

# Listen on a local UDP port and relay rawmsg to multiple destinations.
#
# $listen - host:port to listen for incoming UDP messages
# $destination - array of host:port destinations to "tee" messages

class profile::rsyslog::udp_tee (
    String $listen = lookup('profile::rsyslog::udp_tee::listen', {'default_value' => '0.0.0.0:8420'}),
    Array[String] $destinations = lookup('profile::rsyslog::udp_tee::destinations', {'default_value' => ['localhost:8421']}),
) {
    $listen_host = split($listen, ':')[0]
    $listen_port = split($listen, ':')[1]

    rsyslog::conf { 'udp_tee':
        content  => template('profile/rsyslog/udp_tee.conf.erb'),
        priority => 50,
    }

    # disable escaping of control chars to avoid breaking the formatting of multi-line logs like tracebacks
    rsyslog::conf { 'escape_control_characters_on_receive.conf':
        ensure   => present,
        content  => template('profile/rsyslog/escape_control_characters_on_receive.conf.erb'),
        priority => 00,
    }

    ferm::service { "rsyslog_udp_tee_${listen_port}":
        proto  => 'udp',
        port   => $listen_port,
        srange => '$DOMAIN_NETWORKS',
    }
}
