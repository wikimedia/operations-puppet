# == Class: icinga::monitor::reading_web
#
# Monitor the following Reading Web Grafana dashboards:
#
# * Page Previews Dashboard <grafana.wikimedia.org/dashboard/db/reading-web-page-previews>
class icinga::monitor::reading_web {
    monitoring::grafana_alert { 'reading-web-page-previews':
        dashboard_uid => '000000340',
        contact_group => 'team-reading-web',
    }
}
