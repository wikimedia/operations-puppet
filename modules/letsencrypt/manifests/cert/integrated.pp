#
# Usage:
#
# letsencrypt::cert::integrated { 'example':
#     subjects => 'www.example.com,foo.example.com',
#     pup_svc  => 'nginx', # puppet Service[] name
#     cli_svc  => 'nginx', # for: service $cli_svc reload
# }
#
# See also: the general LE notes in modules/letsencrypt/init.pp
#
# integrated webserver configuration:
#   reference TLS files as e.g.:
#     /etc/acme/key/example.key
#     /etc/acme/cert/example.crt
#     /etc/acme/cert/example.chain.crt
#     /etc/acme/cert/example.chained.crt
#
#   nginx:
#     Include file defines a 'location' for '/.well-known/acme-challenge',
#     put it within 'server' for port 80.  If port 80 redirects to HTTPS, this
#     must be excluded from the redirect by putting the redirect in a separate
#     location block for '/', as in:
#       server {
#         listen 80 ...
#         server_name ...
#         ...
#         include /etc/acme/challenge-nginx.conf;
#         location / {
#           return 301 https://example.wikimedia.org$request_uri
#         }
#       }
#
#   apache: XXX TODO config frag + instructions as above
#
# Notes:
# 1) this does not puppetize OCSP Stapling - probably best doing this in
#    apache/nginx config with existing built-in mechanisms where applicable,
#    and maybe puppetizing that better in shared way.
# 2) This intentionally does not scale for a many certs on one host situation.
#    It would be messy and inefficient, especially on the service reload side.
#    This class is only for the case of one or a few certs on a server - we can
#    write better wrappers for those kinds of special cases...
#

define letsencrypt::cert::integrated($subjects, $pup_svc, $cli_svc) {
    require ::letsencrypt

    $safe_title = regsubst($title, '\W', '_', 'G')
    $base_cmd = "/usr/local/sbin/acme-setup -i ${safe_title} -s ${subjects}"

    # Pre-setup with self-signed cert if necessary, to let $pup_svc start
    exec { "acme-setup-self-${safe_title}":
        command => $base_cmd,
        creates => "/etc/acme/certs/${safe_title}.crt",
        before  => Service[$pup_svc],
    }

    # Post-setup and renewal - runs on every puppet run, creates a new ACME
    # cert and reloads the webserver iff existing cert is self-signed from
    # above or reaches expiry threshold (30-44 days left, deterministically
    # random per unique certificate (will change on renewal)).
    exec { "acme-setup-acme-${safe_title}":
        command => "${base_cmd} -m acme -w ${cli_svc}",
        require => Service[$pup_svc],
    }
}
