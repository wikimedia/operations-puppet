# server running Gerrit code review software
# https://en.wikipedia.org/wiki/Gerrit_%28software%29
#
class role::gerrit {

    system::role { 'Gerrit': description => "Gerrit server in ${::realm}" }

    include ::standard
    include ::profile::backup::host
    include ::profile::base::firewall
    include ::profile::gerrit::server
    include ::profile::rsyslog::kafka_shipper
    include ::profile::waf::apache2::administrative

    class { '::httpd':
        modules => ['rewrite', 'headers', 'proxy', 'proxy_http', 'remoteip', 'ssl'],
    }
}
