# == Class: icinga::monitor::reading_web
#
# Monitor the following Reading Web Grafana dashboards:
#
# * Page Previews Dashboard <grafana.wikimedia.org/dashboard/db/reading-web-page-previews>
class icinga::monitor::reading_web {
    monitoring::grafana_alert { 'reading-web-page-previews':
        dashboard_uid => '000000340',
        contact_group => 'team-reading-web',
        notes_url     => 'https://phabricator.wikimedia.org/rOPUP8e70f242a7888527d6af8ff8d823f82fe0202cd0',
    }
}
