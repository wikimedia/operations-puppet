# SPDX-License-Identifier: Apache-2.0
class alertmanager::irc (
    Stdlib::Host $listen_host = 'localhost',
    Stdlib::Port $listen_port = 19190,
    Stdlib::Host $irc_host = 'localhost',
    Stdlib::Port $irc_port = 6697,
    String $irc_nickname = $title,
    String $irc_realname = $title,
    String $dashboard_url = "https://alerts.${facts['domain']}",
    Optional[String] $irc_nickname_password = undef,
    Stdlib::Ensure::Service $service_ensure = running,
) {
    ensure_packages(['alertmanager-irc-relay'])

    $service_enable = $service_ensure ? {
        running => true,
        stopped => false,
    }

    service { 'alertmanager-irc-relay':
        ensure => $service_ensure,
        enable => $service_enable,
    }

    file { '/etc/alertmanager-irc-relay.yml':
        ensure    => present,
        owner     => 'alertmanager-irc-relay',
        group     => root,
        mode      => '0440',
        show_diff => false,
        content   => template('alertmanager/irc.yml.erb'),
        notify    => Service['alertmanager-irc-relay'],
    }
}
