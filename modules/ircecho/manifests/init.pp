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
# $ircecho_ssl = false # whether to connect to irc using ssl or not
class ircecho (
    $ircecho_logs,
    $ircecho_nick,
    $ircecho_server = 'chat.freenode.net 6667',
    $ensure = 'present',
) {

    require_package(['python-pyinotify', 'python-irc'])

    file { '/usr/local/bin/ircecho':
        ensure => 'present',
        source => 'puppet:///modules/ircecho/ircecho.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { '/etc/default/ircecho':
        ensure  => 'present',
        content => template('ircecho/default.erb'),
        owner   => 'root',
        mode    => '0755',
        notify  => Service['ircecho'],
    }

    base::service_unit { 'ircecho':
        ensure         => $ensure,
        systemd        => systemd_template('ircecho'),
        sysvinit       => sysvinit_template('ircecho'),
        require        => File['/usr/local/bin/ircecho'],
        service_params => {
            hasrestart => true,
        },
    }
}
