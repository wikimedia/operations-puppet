# == Class: icinga::monitor::services
#
# Monitor various Services-related dashboards
class icinga::monitor::services {
    monitoring::grafana_alert { 'restbase-legacy':
        dashboard_uid => '000000068',
        contact_group => 'team-services',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/RESTBase#What_to_check_after_a_deploy',
    }

    monitoring::grafana_alert { 'restbase':
        dashboard_uid => '000000577',
        contact_group => 'team-services',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/RESTBase#What_to_check_after_a_deploy',
    }

    # TODO: change this name to 'change-prop'.  eventbus service is gone.
    # https://phabricator.wikimedia.org/T232122
    monitoring::grafana_alert { 'change-propagation':
        dashboard_uid => '000000201',
        contact_group => 'team-services',
        notes_url     => 'https://www.mediawiki.org/wiki/Change_propagation',
    }

    monitoring::grafana_alert { 'jobqueue-eventbus':
      dashboard_uid => '000000400',
      contact_group => 'team-services',
      notes_url     => 'https://wikitech.wikimedia.org/wiki/Kafka_Job_Queue',
    }
}
