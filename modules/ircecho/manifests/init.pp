# IRC echo class
# To use this class, you must define some parameters; here's an example
# (leading hashes on channel names are added for you if missing):
# $ircecho_logs = {
#  "/var/log/nagios/irc.log" =>
#  ["wikimedia-operations","#wikimedia-tech"],
#  "/var/log/nagios/irc2.log" => "#irc2",
# }
# $ircecho_nick = "icinga-wm"
# $ircecho_server = "chat.freenode.net"
class ircecho (
    $ircecho_logs,
    $ircecho_nick,
    $ircecho_server = 'chat.freenode.net',
) {

    package { 'ircecho':
        ensure => present,
    }

    service { 'ircecho':
        require => Package['ircecho'],
        ensure  => running,
    }

    file { '/etc/default/ircecho':
        require => Package['ircecho'],
        content => template('ircecho/default.erb'),
        owner   => 'root',
        mode    => '0755',
    }
}

