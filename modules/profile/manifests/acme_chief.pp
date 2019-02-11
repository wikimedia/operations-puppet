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
    Hash[String, Hash[String, String]] $accounts = hiera('profile::acme_chief::accounts'),
    Hash[String, Hash[String, Any]] $certificates = hiera('profile::acme_chief::certificates'),
    Hash[String, Hash[String, Any]] $challenges = hiera('profile::acme_chief::challenges'),
    String $http_proxy = hiera('http_proxy'),
    String $active_host = hiera('profile::acme_chief::active'),
    String $passive_host = hiera('profile::acme_chief::passive'),
    Array[String] $authdns_servers = hiera('authdns_servers'),
) {
    class { '::acme_chief::server':
        accounts        => $accounts,
        certificates    => $certificates,
        challenges      => $challenges,
        http_proxy      => $http_proxy,
        active_host     => $active_host,
        passive_host    => $passive_host,
        authdns_servers => $authdns_servers,
    }
}
