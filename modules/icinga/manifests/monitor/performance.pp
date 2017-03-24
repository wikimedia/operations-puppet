# == Class: icinga::monitor::performance
#
# Monitor Performance
class icinga::monitor::performance {
    monitoring::grafana_alert { 'db/webpagetest-alerts':
        contact_group   => 'team-performance',
    }
}
