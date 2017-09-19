# == Class: base::remote_syslog
#
# Configure rsyslog to forward log events to a central server
#
# === Parameters
#
# [*enable*]
#   Enable log forwarding. Should be set to false on the central server.
#
# [*central_hosts*]
#   A list of host (and optional port) to forward syslog events to.
#   (e.g. ["syslog.eqiad.wmnet"] or ["deployment-logstash2.deployment-prep.eqiad.wmflabs:10514"])
#
# [*central_hosts_tls*]
#   A list of host:port (port is *required*) to forward syslog using TLS.
#   (e.g. ["syslog.eqiad.wmnet:6154"])
#
#
class base::remote_syslog (
    $enable,
    $central_hosts = [],
    $central_hosts_tls = [],
) {
    if $enable {
        require_package('rsyslog-gnutls')

        if empty($central_hosts) and empty($central_hosts_tls) {
            fail('::base::remote_syslog::central_hosts central_hosts_tls required')
        }

        if ! empty($central_hosts_tls) {
            ::base::expose_puppet_certs { '/etc/rsyslog':
                provide_private => true,
            }
        }

        rsyslog::conf { 'remote_syslog':
            content  => template('base/remote_syslog.conf.erb'),
            priority => 30,
        }
    }
    # No ensure=>absent handling is needed for the $enable == false case
    # because ::rsyslog uses recursive purge to manage the files in its config
    # directory. Simply not adding the file will cause Puppet to remove it if
    # present.
}
