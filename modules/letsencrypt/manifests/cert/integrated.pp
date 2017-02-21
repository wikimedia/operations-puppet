# == Define: letsencrypt::cert::integrated
#
# This defines a TLS certificate which is automatically acquired
# and renewed from letsencrypt.org.  This particular puppetization
# ("integrated") requires that:
#
# 1. The certificate hostnames are publicly-accessible over HTTP on the same
#    machine the certificate is being provisioned on.
# 2. The machine has public network access.
# 3. The server software is capable of mapping a URI path to an arbitrary
#    filesystem path, and is configured to do so, mapping
#    '/.well-known/acme-challenge' to '/var/acme/challenge'.
# 4. The software loads new certs when commanded via 'service foo reload'
#
# The actual output key/cert files will be at the follow paths for
# the web server's configuration to consume.
#
# Private Key:       /etc/acme/key/${title}.key
# Public Cert:       /etc/acme/cert/${title}.crt
# Intermediate:      /etc/acme/cert/${title}.chain.crt
# Cert+Intermediate: /etc/acme/cert/${title}.chained.crt
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
# See also: the general LE notes in modules/letsencrypt/init.pp
#
# === Parameters
#
# [*subjects*]
#   The list of FQDNs the cert should be valid for, comma-separated.  The ACME
#   challenge must work for all of these hostnames (they must all be configured
#   in the webserver as legitimate HTTP hostnames).
#
# [*puppet_svc*]
#   The puppet service name of the webserver for use in Service[] dependency
#   references, usually 'nginx' or 'apache2'.
#
# [*system_svc*]
#   The system-level service name for the same as the above, for use in commands
#   like: 'service $system_service reload'
#
# [*key_user*]
#   The system user name which should own the private key, defaults to root
#
# [*key_group*]
#   The system group name which should own the private key, defaults to root
#
# === Hieradata control: do_acme
#
# If the hieradata key 'do_acme' is set to false (default is true), the
# self-signed cert creation steps will still occur before web service start,
# allowing puppet to run successfully for all other purposes, but the actual
# ACME fetch of a real cert from letsencrypt.org will be disabled, and the
# service will only be provisioned with the self-signed cert.
#
# If you're provisioning a new replacement host for an existing service, or for
# some other reason the public hostname the certificate for will not yet be
# mapped to this host when you initially puppet it in a way that includes a
# letsencrypt certificate, setting 'do_acme: false' is probably want you want to
# do temporarily in hieradata/hosts/HOSTNAME.yaml .  You can then remove this
# entry after the public name is mapped (in DNS, LVS, etc) to this host so that
# it can answer challenges and obtain a real, signed certificate for itself.
#
# === Examples
#
# letsencrypt::cert::integrated { 'example':
#     subjects   => 'www.example.com,foo.example.com',
#     puppet_svc => 'nginx',
#     system_svc => 'nginx',
# }
#
# integrated webserver configuration:
#   nginx:
#     An include file will exist as /etc/acme/challenge-nginx.conf
#     It defines a 'location' for '/.well-known/acme-challenge', and should be
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
#   apache:
#     An include file will exist as /etc/acme/challenge-apache.conf
#     This defines an alias for '/.well-known/acme-challenge' and a <Directory>
#     stanza to grant permissions there, and needs to be in the port 80 virtual
#     host.  If port 80 redirects to HTTPS universally, you'll need to exclude
#     the challenge path from the redirect, as in this example:
#       <VirtualHost *:80>
#         ServerName ....
#         ...
#         Include /etc/acme/challenge-apache.conf
#         RewriteEngine on
#         RewriteCond %{REQUEST_URI} !^/\.well-known/acme-challenge/
#         RewriteRule ^/(.*)$ https://example.wikimedia.org/$1 [R=301]
#       </VirtualHost>
#

define letsencrypt::cert::integrated($subjects, $puppet_svc, $system_svc, $key_user='root', $key_group='root') {
    require ::letsencrypt

    $safe_title = regsubst($title, '\W', '_', 'G')
    $base_cmd = "/usr/local/sbin/acme-setup -i ${safe_title} -s ${subjects} --key-user ${key_user} --key-group ${key_group}"

    # Pre-setup with self-signed cert if necessary, to let $puppet_svc start
    exec { "acme-setup-self-${safe_title}":
        command => $base_cmd,
        creates => "/etc/acme/cert/${safe_title}.crt",
        before  => Service[$puppet_svc],
    }

    if hiera('do_acme', true) {
        # Post-setup and renewal - runs on every puppet run, creates a new ACME
        # cert and reloads the webserver iff existing cert is self-signed from
        # above or reaches expiry threshold (30-44 days left, deterministically
        # random per unique certificate (will change on renewal)).
        exec { "acme-setup-acme-${safe_title}":
            command => "${base_cmd} -m acme -w ${system_svc}",
            require => Service[$puppet_svc],
        }
    }
}
