# Certcentral server
# For clients you'll want some resources like this:
#     certcentral::cert { 'testing':
#        puppet_svc => 'nginx'
#    }

# and if you want to support http-01 challenges, some nginx config like this:
# server {
#        listen [::]:443 default_server deferred backlog=16384 reuseport ssl http2;
#        listen 443 default_server deferred backlog=16384 reuseport ssl http2;
#        server_name certcentraltest.beta.wmflabs.org;
#        error_log   /var/log/nginx/certcentral.client.error.log;
#        access_log   off;
#        ssl_certificate /etc/centralcerts/testing.rsa-2048.fullchain.pem;
#        ssl_certificate_key /etc/centralcerts/testing.rsa-2048.private.pem;
#        keepalive_timeout 60;
#        location /.well-known/acme-challenge/ {
#                proxy_pass http://certcentral_hostname_here;
#        }
#}
#server {
#        listen [::]:80 deferred backlog=16384 reuseport ipv6only=on;
#        listen 80 deferred backlog=16384 reuseport;
#        server_name certcentraltest.beta.wmflabs.org;
#        error_log   /var/log/nginx/certcentral.client.error.log;
#        access_log   off;
#        keepalive_timeout 60;
#        location /.well-known/acme-challenge/ {
#                proxy_pass http://certcentral_hostname_here;
#        }
#}
# and mark your nginx::site with require => Certcentral::Cert['testing']

class profile::certcentral (
    Hash[String, Hash[String, String]] $accounts = hiera('profile::certcentral::accounts'),
    Hash[String, Hash[String, Any]] $certificates = hiera('profile::certcentral::certificates'),
    Hash[String, Hash[String, Any]] $challenges = hiera('profile::certcentral::challenges'),
    String $http_proxy = hiera('http_proxy'),
    String $active_host = hiera('profile::certcentral::active'),
    String $passive_host = hiera('profile::certcentral::passive'),
    Array[String] $authdns_servers = hiera('authdns_servers'),
) {
    File <<| tag == 'certcentral-authorisedhosts' |>> ~> Base::Service_unit['uwsgi-certcentral']

    class { '::certcentral::server':
        accounts        => $accounts,
        certificates    => $certificates,
        challenges      => $challenges,
        http_proxy      => $http_proxy,
        active_host     => $active_host,
        passive_host    => $passive_host,
        authdns_servers => $authdns_servers,
    }
}
