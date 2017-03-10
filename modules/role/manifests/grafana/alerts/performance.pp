# == Class: role::grafana::alerts::performance
#
class role::grafana::alerts::performance {
    monitoring::grafana_alert { 'db/webpagetest-alerts':
        contact_group   => 'performance',
    }
}
