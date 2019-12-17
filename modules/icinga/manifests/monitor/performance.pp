# == Class: icinga::monitor::performance
#
# Monitor Performance
class icinga::monitor::performance {
    monitoring::grafana_alert { 'webpagetest-alerts':
        dashboard_uid => '000000318',
        contact_group => 'team-performance',
        notes_url     => 'https://phabricator.wikimedia.org/T203485',
    }

    monitoring::grafana_alert { 'navigation-timing-alerts':
        dashboard_uid => '000000326',
        contact_group => 'team-performance',
        notes_url     => 'https://phabricator.wikimedia.org/T203485',
    }

    monitoring::grafana_alert { 'save-timing-alerts':
        dashboard_uid => '000000362',
        contact_group => 'team-performance',
        notes_url     => 'https://phabricator.wikimedia.org/T203485',
    }

    monitoring::grafana_alert { 'resourceloader-alerts':
        dashboard_uid => '000000402',
        contact_group => 'team-performance',
        notes_url     => 'https://phabricator.wikimedia.org/T203485',
    }

    monitoring::grafana_alert { 'webpagereplay-en-wikipedia-org-alerts':
        dashboard_uid => '2kP3FjAZk',
        contact_group => 'team-performance',
        notes_url     => 'https://phabricator.wikimedia.org/T203485',
    }

    monitoring::grafana_alert { 'webpagereplay-ca-wikipedia-org-alerts':
        dashboard_uid => '2kP3FjAZE',
        contact_group => 'team-performance',
        notes_url     => 'https://phabricator.wikimedia.org/T203485',
    }

    monitoring::grafana_alert { 'webpagereplay-de-wikipedia-org-alerts':
        dashboard_uid => '2kP3FjAZB',
        contact_group => 'team-performance',
        notes_url     => 'https://phabricator.wikimedia.org/T203485',
    }

    monitoring::grafana_alert { 'webpagereplay-en-wikipedia-beta-wmflabs-org-alerts':
        dashboard_uid => '2kP3FjAZE',
        contact_group => 'team-performance',
        notes_url     => 'https://phabricator.wikimedia.org/T203485',
    }

    monitoring::grafana_alert { 'webpagereplay-es-wikipedia-org-alerts':
        dashboard_uid => '2kP3FjAZZ',
        contact_group => 'team-performance',
        notes_url     => 'https://phabricator.wikimedia.org/T203485',
    }

    monitoring::grafana_alert { 'webpagereplay-fr-wikipedia-org-alerts':
        dashboard_uid => '2kP3FjAZX',
        contact_group => 'team-performance',
        notes_url     => 'https://phabricator.wikimedia.org/T203485',
    }

    monitoring::grafana_alert { 'webpagereplay-js-wikipedia-org-alerts':
        dashboard_uid => '2kP3FjAZXX',
        contact_group => 'team-performance',
        notes_url     => 'https://phabricator.wikimedia.org/T203485',
    }

    monitoring::grafana_alert { 'webpagereplay-nl-wikipedia-org-alerts':
        dashboard_uid => '2kP3FjAZC',
        contact_group => 'team-performance',
        notes_url     => 'https://phabricator.wikimedia.org/T203485',
    }
    monitoring::grafana_alert { 'webpagereplay-sv-wikipedia-org-alerts':
        dashboard_uid => '2kP3FjAZA',
        contact_group => 'team-performance',
        notes_url     => 'https://phabricator.wikimedia.org/T203485',
    }

    monitoring::grafana_alert { 'webpagereplay-www-mediawiki-org-alerts':
        dashboard_uid => '2kP3FjAXX',
        contact_group => 'team-performance',
        notes_url     => 'https://phabricator.wikimedia.org/T203485',
    }

    monitoring::grafana_alert { 'webpagereplay-zh-wikipedia-org-alerts':
        dashboard_uid => '2kP3FjDGT',
        contact_group => 'team-performance',
        notes_url     => 'https://phabricator.wikimedia.org/T203485',
    }

    monitoring::grafana_alert { 'webpagereplay-ru-wikipedia-org-alerts':
        dashboard_uid => '2kP3FjAZP',
        contact_group => 'team-performance',
        notes_url     => 'https://phabricator.wikimedia.org/T203485',
    }
}
