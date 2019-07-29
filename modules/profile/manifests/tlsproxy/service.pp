# = Class profile::tlsproxy::service
#
# == Parameters
#
# [*cert_domain_name*]
#   The fully qualified name of the domain used to create the TLS
#   certificate in puppet.
#
# [*upstream_ports*]
#   The port of the upstream service that needs to be proxied.
#
# [*ocsp_proxy*]
#   The protocol:hostname:port combination of the OCSP server
#   to use in the nginx config.
#   Default: 'http_proxy' in hiera
#
# [*notes_url*]
#   The URL of the Wikitech page containing information about
#   the service and the HTTPS monitoring check.
#
# [*check_uri*]
#   The URI part of the Nagios HTTPS check command.
#   Default: '/'
#
# [*check_service*]
#   The fully qualified domain name of the service to check. This
#   can be different from $cert_domain_name when a single TLS certificate
#   is used for multiple domains (listed as SANs).
#   If undef the monitored service name will be the one indicated by
#   $cert_domain_name.
#   Default: undef
#
# [*contact_group*]
#   The Nagios contact group for the HTTPS check.
#   Default: 'admin'
#
class profile::tlsproxy::service(
    String $cert_domain_name = lookup('profile::tlsproxy::service::cert_domain_name'),
    Array[Stdlib::Port] $upstream_ports = lookup('profile::tlsproxy::service::upstream_ports'),
    String $ocsp_proxy = lookup('http_proxy'),
    String $notes_url = lookup('profile::tlsproxy::service::notes_url'),
    String $check_uri = lookup('profile::tlsproxy::service::check_uri', '/'),
    Optional[String] $check_service = lookup('profile::tlsproxy::service::check_service', { 'default_value' => undef }),
    String $contact_group = lookup('profile::tlsproxy::service::contact_group', { 'default_value' => 'admin' }),
) {
    tlsproxy::localssl { $cert_domain_name:
        server_name     => $cert_domain_name,
        certs           => [$cert_domain_name],
        upstream_ports  => $upstream_ports,
        default_server  => true,
        ocsp_proxy      => $ocsp_proxy,
        ssl_ecdhe_curve => false,
    }

    # In case a single TLS certificate is used for multiple
    # domains, we need a way to specify what is the domain
    # to use in the Nagios command.
    if $check_service {
        $monitored_servicename = $check_service
    } else {
        $monitored_servicename = $cert_domain_name
    }

    $check_command = "check_https_url!${monitored_servicename}!${check_uri}"

    monitoring::service { "${monitored_servicename}-https":
        description   => "${monitored_servicename} HTTPS",
        check_command => $check_command,
        notes_url     => $notes_url,
        contact_group => $contact_group,
    }

    ferm::service { "${monitored_servicename}-proxy-https":
        proto   => 'tcp',
        notrack => true,
        port    => '443',
    }
}
