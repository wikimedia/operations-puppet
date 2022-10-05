# SPDX-License-Identifier: Apache-2.0
class profile::wmcs::metricsinfra::alertmanager::irc (
    Stdlib::Host        $active_host  = lookup('profile::wmcs::metricsinfra::alertmanager_active_host'),
    Stdlib::Host        $irc_host     = lookup('profile::wmcs::metricsinfra::alertmanager::irc::host', {default_value => 'irc.libera.chat'}),
    Stdlib::Port        $irc_port     = lookup('profile::wmcs::metricsinfra::alertmanager::irc::port', {default_value => 6697}),
    String              $irc_nickname = lookup('profile::wmcs::metricsinfra::alertmanager::irc::nickname'),
    String              $irc_realname = lookup('profile::wmcs::metricsinfra::alertmanager::irc::realname'),
    String              $irc_password = lookup('profile::wmcs::metricsinfra::alertmanager::irc::password'),
    String              $vhost        = lookup('profile::wmcs::metricsinfra::alertmanager::vhost', {default_value => 'prometheus-alerts.wmcloud.org'}),
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
        irc_nickname_password => $irc_password,
        service_ensure        => $irc_ensure,
        dashboard_url         => "https://${vhost}",
    }
}
