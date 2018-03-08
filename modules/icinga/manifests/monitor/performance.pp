# == Class: icinga::monitor::performance
#
# Monitor Performance
class icinga::monitor::performance {
    monitoring::grafana_alert { 'db/webpagetest-alerts':
        contact_group   => 'team-performance',
    }

    monitoring::grafana_alert { 'db/navigation-timing-alerts':
        contact_group   => 'team-performance',
    }

    monitoring::grafana_alert { 'db/save-timing-alerts':
        contact_group   => 'team-performance',
    }

    monitoring::grafana_alert { 'db/resourceloader-alerts':
        contact_group   => 'team-performance',
    }

    monitoring::grafana_alert { 'db/webpagereplay-desktop-alerts':
        contact_group   => 'team-performance',
    }

    monitoring::grafana_alert { 'webpagereplay-mobile-alerts':
        contact_group   => 'team-performance',
    }
}
