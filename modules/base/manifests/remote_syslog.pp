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
#   (e.g. "syslog.eqiad.wmnet" or "deployment-logstash1.eqiad.wmflabs:10514")
#
#
class base::remote_syslog (
    $enable,
    $central_host,
) {
    if $enable {
        rsyslog::conf { 'remote_syslog':
            content  => "*.info;mail.none;authpriv.none;cron.none @${syslog_host}",
            priority => 30,
        }
    }
}
