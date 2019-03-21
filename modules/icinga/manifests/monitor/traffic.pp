# == Class: icinga::monitor::traffic
#
# Monitor Traffic
class icinga::monitor::traffic {
    monitoring::grafana_alert { 'varnish-http-requests':
      dashboard_uid => '000000180',
      notes_url     => 'https://phabricator.wikimedia.org/project/view/1201/',
    }
    monitoring::grafana_alert { 'ping-offload':
      dashboard_uid => '000000513',
      notes_url     => 'https://wikitech.wikimedia.org/wiki/Ping_offload#InAddrErrors_alert',
    }
}
