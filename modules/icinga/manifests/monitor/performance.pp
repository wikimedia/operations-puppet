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

    monitoring::grafana_alert { 'webpagereplay-desktop-alerts':
        dashboard_uid => '000000491',
        contact_group => 'team-performance',
        notes_url     => 'https://phabricator.wikimedia.org/T203485',
    }

    monitoring::grafana_alert { 'webpagereplay-mobile-alerts':
        dashboard_uid => '000000490',
        contact_group => 'team-performance',
        notes_url     => 'https://phabricator.wikimedia.org/T203485',
    }
}
