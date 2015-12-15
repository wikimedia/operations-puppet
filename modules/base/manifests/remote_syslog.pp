# == Class: base::remote_syslog
#
# Configure rsyslog to forward log events to a central server
#
# === Parameters
#
# [*enable*]
#   Enable log forwarding. Should be set to false on the central server.
#
# [*central_host*]
#   Host (and optional port) to forward syslog events to.
#   (e.g. "syslog.eqiad.wmnet" or "deployment-logstash2.deployment-prep.eqiad.wmflabs:10514")
#
#
class base::remote_syslog (
    $enable,
    $central_host = undef,
) {
    if $enable {
        if $central_host == undef {
            fail('::base::remote_syslog::central_host required')
        }

        rsyslog::conf { 'remote_syslog':
            content  => template('base/remote_syslog.conf.erb')
            priority => 30,
        }
    }
    # No ensure=>absent handling is needed for the $enable == false case
    # because ::rsyslog uses recursive purge to manage the files in its config
    # directory. Simply not adding the file will cause Puppet to remove it if
    # present.
}
