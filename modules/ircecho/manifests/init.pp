# IRC echo class
# To use this class, you must define some parameters; here's an example
# (leading hashes on channel names are added for you if missing):
# $ircecho_logs = {
#  "/var/log/nagios/irc.log" =>
#  ["wikimedia-operations","#wikimedia-tech"],
#  "/var/log/nagios/irc2.log" => "#irc2",
# }
# $ircecho_nick = "icinga-wm"
# $ircecho_server = "chat.freenode.net 6667"
class ircecho (
    $ircecho_logs,
    $ircecho_nick,
    $ircecho_server = 'chat.freenode.net +6697',
    $ident_passwd_file = undef,
    $ensure = 'present',
) {

    require_package(['python-pyinotify', 'python-irc'])

    file { '/usr/local/bin/ircecho':
        ensure => 'present',
        source => 'puppet:///modules/ircecho/ircecho.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        notify => Service['ircecho'],
    }
    file { '/usr/local/lib/python2.7/dist-packages/ib3_auth.py':
        ensure => 'present',
        source => 'puppet:///modules/ircecho/ib3_auth.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        notify => Service['ircecho'],
    }

    file { '/etc/default/ircecho':
        ensure  => 'present',
        content => template('ircecho/default.erb'),
        owner   => 'root',
        mode    => '0755',
        notify  => Service['ircecho'],
    }

    systemd::service { 'ircecho':
        ensure         => $ensure,
        content        => systemd_template('ircecho'),
        service_params => {
            hasrestart => true,
        },
        require        => File['/usr/local/bin/ircecho'],
    }


    base::service_auto_restart { 'ircecho': }
}
