# == Class: icinga::monitor::services
#
# Monitor various Services-related dashboards
class icinga::monitor::services {
    monitoring::grafana_alert { 'restbase':
        contact_group   => 'team-services',
    }

    monitoring::grafana_alert { 'api-summary':
        contact_group   => 'team-services',
    }

    monitoring::grafana_alert { 'services-alerts':
        contact_group   => 'team-services',
    }

    monitoring::grafana_alert { 'eventbus':
        contact_group   => 'analytics,team-services',
    }

    monitoring::grafana_alert { 'jobqueue-eventbus':
      contact_group   => 'team-services',
    }
}
