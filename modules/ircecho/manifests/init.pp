# SPDX-License-Identifier: Apache-2.0
# IRC echo class
# To use this class, you must define some parameters; here's an example
# (leading hashes on channel names are added for you if missing):
# $ircecho_logs = {
#  "/var/log/nagios/irc.log" =>
#  ["wikimedia-operations","#wikimedia-tech"],
#  "/var/log/nagios/irc2.log" => "#irc2",
# }
# $ircecho_nick = "icinga-wm"
# $ircecho_server = "irc.libera.chat 6667"
class ircecho (
    $ircecho_logs,
    $ircecho_nick,
    $ircecho_server = 'irc.libera.chat +6697',
    $ident_passwd_file = undef,
    $ensure = 'present',
) {

    if debian::codename::eq('bookworm') {
        ensure_packages(['python3-pyinotify', 'python3-irc'])

        file { '/usr/local/bin/ircecho':
            ensure => 'present',
            source => 'puppet:///modules/ircecho/ircecho3.py',
            mode   => '0755',
            notify => Service['ircecho'],
        }

        file { '/usr/local/lib/python3.11/dist-packages/ib3_auth.py':
            ensure => 'present',
            source => 'puppet:///modules/ircecho/ib3_auth.py',
            mode   => '0755',
            notify => Service['ircecho'],
        }
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

    profile::auto_restarts::service { 'ircecho':
        ensure => $ensure,
    }
}
