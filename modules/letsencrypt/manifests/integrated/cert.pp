#
# Usage:
#
# letsencrypt::integrated::cert { 'examplecert':
#     subjects => 'www.example.com,example.com',
#     pup_svc  => 'nginx',
#     cli_svc  => 'nginx',
# }
#
# integrated webserver configuration:
#   nginx: put this in server config stanza(s):
#     include /etc/acme/challenge-nginx.conf;
#   apache: XXX TODO like above
#   both: reference TLS files as e.g.:
#     /etc/acme/key/examplecert.key
#     /etc/acme/cert/examplecert.crt
#     /etc/acme/cert/examplecert.chain.crt
#

define letsencrypt::integrated::cert($subjects, $pup_svc, $cli_svc) {
    require ::letsencrypt

    $safe_title = $title # XXX clean up metachars
    $base_cmd = "/usr/local/sbin/acme-setup -i ${safe_title} -s ${subjects}"

    exec { 'acme-setup-self-$safe_title':
        command => $base_cmd,
        before  => Service[$pup_svc],
    }

    exec { 'acme-setup-acme-$safe_title':
        command => "${base_cmd} -m acme",
        require => Service[$pup_svc],
    }

    # XXX TODO: generate .chain.crt + .chained.crt in both cases above, not sure if here, in acme-setup, in wrapper for acme-setup, ?
    # XXX TODO: deal with execution of "service $cli_svc reload" iff crt updated
    # XXX TODO: make service reload scale well for many certs without spamming reload
    # XXX TODO: integrate OCSP stapling, too
}
