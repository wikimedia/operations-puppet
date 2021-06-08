# == Class: icinga::monitor::reading_web
#
# Monitor Reading Web Grafana dashboards:
class icinga::monitor::reading_web {
    monitoring::grafana_alert { 'wikimedia-client-errors-alerts':
        dashboard_uid => '000000566',
        contact_group => 'team-reading-web,admins',
        notes_url     => 'https://logstash.wikimedia.org/app/kibana#/dashboard/AXDBY8Qhh3Uj6x1zCF56'
    }
}
