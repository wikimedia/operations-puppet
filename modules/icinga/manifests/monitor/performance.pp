# == Class: icinga::monitor::performance
#
# Monitor Performance
class icinga::monitor::performance {
    monitoring::grafana_alert { 'webpagetest-alerts':
        contact_group => 'team-performance',
        notes_url     => 'https://phabricator.wikimedia.org/T203485',
    }

    monitoring::grafana_alert { 'navigation-timing-alerts':
        contact_group => 'team-performance',
        notes_url     => 'https://phabricator.wikimedia.org/T203485',
    }

    monitoring::grafana_alert { 'save-timing-alerts':
        contact_group => 'team-performance',
        notes_url     => 'https://phabricator.wikimedia.org/T203485',
    }

    monitoring::grafana_alert { 'resourceloader-alerts':
        contact_group => 'team-performance',
        notes_url     => 'https://phabricator.wikimedia.org/T203485',
    }

    monitoring::grafana_alert { 'webpagereplay-desktop-alerts':
        contact_group => 'team-performance',
        notes_url     => 'https://phabricator.wikimedia.org/T203485',
    }

    monitoring::grafana_alert { 'webpagereplay-mobile-alerts':
        contact_group => 'team-performance',
        notes_url     => 'https://phabricator.wikimedia.org/T203485',
    }
}
