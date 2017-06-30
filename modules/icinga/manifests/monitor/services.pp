# == Class: icinga::monitor::performance
#
# Monitor Performance
class icinga::monitor::services {
    monitoring::grafana_alert { 'db/restbase':
        contact_group   => 'team-services',
    }

    monitoring::grafana_alert { 'db/api-summary':
        contact_group   => 'team-services',
    }

    monitoring::grafana_alert { 'db/services-alerts':
        contact_group   => 'team-services',
    }

    monitoring::grafana_alert { 'db/eventbus':
        contact_group   => 'team-services',
    }
} 
