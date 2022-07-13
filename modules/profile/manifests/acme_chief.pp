# SPDX-License-Identifier: Apache-2.0
# acme-chief server
# For clients you'll want some resources like this:
#     acme_chief::cert { 'testing':
#        puppet_svc => 'nginx'
#    }

# and if you want to support http-01 challenges, some nginx config like this:
# server {
#        listen [::]:443 default_server deferred backlog=16384 reuseport ssl http2;
#        listen 443 default_server deferred backlog=16384 reuseport ssl http2;
#        server_name acmechieftest.beta.wmflabs.org;
#        error_log   /var/log/nginx/acmechief.client.error.log;
#        access_log   off;
#        ssl_certificate /etc/acmecerts/testing.rsa-2048.fullchain.pem;
#        ssl_certificate_key /etc/acmecerts/testing.rsa-2048.private.pem;
#        keepalive_timeout 60;
#        location /.well-known/acme-challenge/ {
#                proxy_pass http://acmechief_hostname_here;
#        }
#}
#server {
#        listen [::]:80 deferred backlog=16384 reuseport ipv6only=on;
#        listen 80 deferred backlog=16384 reuseport;
#        server_name acmechieftest.beta.wmflabs.org;
#        error_log   /var/log/nginx/acmechief.client.error.log;
#        access_log   off;
#        keepalive_timeout 60;
#        location /.well-known/acme-challenge/ {
#                proxy_pass http://acmechief_hostname_here;
#        }
#}
# and mark your nginx::site with require => Acme_chief::Cert['testing']

class profile::acme_chief (
    Hash[String, Hash[String, String]] $accounts = lookup('profile::acme_chief::accounts'),
    Hash[String, Acme_chief::Certificate] $certificates = lookup('profile::acme_chief::certificates'),
    Hash[String, Acme_chief::Certificate] $shared_acme_certificates = lookup('shared_acme_certificates', {default_value => {}}),
    Hash[String, Hash[String, Any]] $challenges = lookup('profile::acme_chief::challenges'),
    String $http_proxy = lookup('http_proxy'),
    String $active_host = lookup('profile::acme_chief::active'),
    String $passive_host = lookup('profile::acme_chief::passive'),
    Hash[Stdlib::Fqdn, Stdlib::IP::Address::Nosubnet] $authdns_servers = lookup('authdns_servers'),
    Integer $watchdog_sec = lookup('profile::acme_chief::watchdog_sec', {default_value => 600}),
) {
    $internal_domains = ['wmnet']
    $acme_chief_certificates = $certificates + $shared_acme_certificates
    $acme_chief_certificates.each |$cert, $config| {
        if $config['CN'].stdlib::end_with($internal_domains) {
            fail("${cert} CN (${config['CN']}) contains internal domain")
        }
        $config['SNI'].each |$sni| {
            if $sni.stdlib::end_with($internal_domains) {
                fail("${cert} SNI (${sni}) contains internal domain")
            }
        }
    }

    class { '::acme_chief::server':
        accounts      => $accounts,
        certificates  => $acme_chief_certificates,
        challenges    => $challenges,
        http_proxy    => $http_proxy,
        active_host   => $active_host,
        passive_host  => $passive_host,
        authdns_hosts => $authdns_servers.keys(),
        watchdog_sec  => $watchdog_sec,
    }
}
