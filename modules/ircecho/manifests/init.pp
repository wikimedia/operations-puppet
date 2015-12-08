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

    if os_version('debian >= jessie') {
        require_package(['python-pyinotify', 'python-irc'])
    } else {
        require_package(['python-pyinotify', 'python-irclib'])
    }

    file { '/usr/local/bin/ircecho':
        ensure => present,
        source => 'puppet:///modules/ircecho/ircecho',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { '/etc/init.d/ircecho':
        ensure => present,
        source => 'puppet:///modules/ircecho/ircecho.init',
        owner  => 'root',
        group  => 'root',
        mode   => '0544',
    }

    file { '/etc/default/ircecho':
        content => template('ircecho/default.erb'),
        owner   => 'root',
        mode    => '0755',
    }

    service { 'ircecho':
        ensure    => running,
        subscribe => File[
            '/usr/local/bin/ircecho',
            '/etc/init.d/ircecho',
            '/etc/default/ircecho'
        ],
    }

}

