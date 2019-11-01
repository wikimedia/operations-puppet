# server running Gerrit code review software
# https://en.wikipedia.org/wiki/Gerrit_%28software%29
#
class role::gerrit {

    system::role { 'Gerrit': description => "Gerrit server in ${::realm}" }

    include ::profile::standard
    include ::profile::backup::host
    include ::profile::base::firewall
    include ::passwords::gerrit
    include ::profile::gerrit::server
    include ::profile::waf::apache2::administrative

    class { '::httpd':
        modules => ['rewrite', 'headers', 'proxy', 'proxy_http', 'remoteip', 'ssl'],
    }
}
