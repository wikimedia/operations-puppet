# == Class: icinga::monitor::services
#
# Monitor various Services-related dashboards
class icinga::monitor::services {
    monitoring::grafana_alert { 'restbase':
        dashboard_uid => '000000068',
        contact_group => 'team-services',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/RESTBase#What_to_check_after_a_deploy',
    }

    monitoring::grafana_alert { 'eventbus':
        dashboard_uid => '000000201',
        contact_group => 'analytics,team-services',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/EventBus',
    }

    monitoring::grafana_alert { 'jobqueue-eventbus':
      dashboard_uid => '000000400',
      contact_group => 'team-services',
      notes_url     => 'https://wikitech.wikimedia.org/wiki/EventBus',
    }
}
