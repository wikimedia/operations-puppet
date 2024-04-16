# SPDX-License-Identifier: Apache-2.0
class profile::alertmanager::irc (
    Stdlib::Host        $active_host = lookup('profile::alertmanager::active_host'),
    Array[Stdlib::Host] $partners    = lookup('profile::alertmanager::partners'),
    Stdlib::Host        $irc_host    = lookup('profile::alertmanager::irc::host'),
    Stdlib::Port        $irc_port    = lookup('profile::alertmanager::irc::port'),
    String              $irc_nickname = lookup('profile::alertmanager::irc::nickname'),
    String              $irc_realname = lookup('profile::alertmanager::irc::realname'),
    String              $irc_nickname_password = lookup('profile::alertmanager::irc::nickname_password'),
    String              $vhost = lookup('profile::alertmanager::web::vhost'),
) {
    if $active_host == $::fqdn {
        $irc_ensure = running
    } else {
        $irc_ensure = stopped
    }

    class { 'alertmanager::irc':
        listen_host           => '0.0.0.0',
        listen_port           => 19190,
        irc_host              => $irc_host,
        irc_port              => $irc_port,
        irc_nickname          => $irc_nickname,
        irc_realname          => $irc_realname,
        irc_nickname_password => $irc_nickname_password,
        service_ensure        => $irc_ensure,
        dashboard_url         => "https://${vhost}",
    }

    # API (webhook)
    firewall::service { 'alertmanager-irc':
        proto  => 'tcp',
        port   => 19190,
        srange => $partners + $active_host,
    }
}
