# vim:sw=4 ts=4 sts=4 et:

# = Define: logstash::input::irc
#
# Configure logstash to collect input from an IRC channel
#
# == Parameters:
# - $ensure: Whether the config should exist. Default: present.
# - $host: IRC server to contact. Default: chat.freenode.net.
# - $port: IRC server port. Default: 6697
# - $secure: Eanble SSL. Default: true
# - $user: IRC username. Default: 'logstash'
# - $password: IRC server password (not NickServ password) Default: undef
# - $nick: IRC nickname. Default: logstash
# - $real: IRC Real name. Default: 'logstash'
# - $channels: List of channels to join. Required.
# - $priority: Configuration loading priority. Default '10'.
#
# == Sample usage:
#
#   logstash::inputs::irc { 'freenode':
#       channels => ['#wikimedia-labs'],
#   }
#
define logstash::input::irc(
    $ensure    = present,
    $host      = 'chat.freenode.net',
    $port      = 6697,
    $secure    = true,
    $user      = 'logstash',
    $password  = undef,
    $nick      = 'logstash',
    $real      = 'logstash',
    $channels,
    $priority  = 10,
) {
    logstash::conf { "input-irc${title}":
        ensure   => $ensure,
        content  => template('logstash/input/irc.erb'),
        priority => $priority,
    }
}
