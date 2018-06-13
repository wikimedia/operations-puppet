# == Class: icinga::monitor::traffic
#
# Monitor Traffic
class icinga::monitor::traffic {
    monitoring::grafana_alert { 'db/varnish-http-requests':
    }
}
