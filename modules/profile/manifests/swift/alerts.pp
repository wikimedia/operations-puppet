class profile::swift::alerts {
    ['eqiad', 'codfw'].each |String $site| {
        monitoring::check_prometheus { "swift-${site}-container-availability":
            description     => "swift ${site} container availability low",
            dashboard_links => ["https://grafana.wikimedia.org/d/OPgmB1Eiz/swift?panelId=8&fullscreen&orgId=1&var-DC=${site}"],
            query           => 'swift_dispersion_container_pct_found',
            warning         => 95,
            critical        => 90,
            method          => 'lt',
            retries         => 10,
            prometheus_url  => "http://prometheus.svc.${site}.wmnet/ops",
            notes_link      => 'https://wikitech.wikimedia.org/wiki/Swift/How_To',
        }

        monitoring::check_prometheus { "swift-${site}-object-availability":
            description     => "swift ${site} object availability low",
            dashboard_links => ["https://grafana.wikimedia.org/d/OPgmB1Eiz/swift?panelId=8&fullscreen&orgId=1&var-DC=${site}"],
            query           => 'swift_dispersion_object_pct_found',
            warning         => 95,
            critical        => 90,
            method          => 'lt',
            retries         => 10,
            prometheus_url  => "http://prometheus.svc.${site}.wmnet/ops",
            notes_link      => 'https://wikitech.wikimedia.org/wiki/Swift/How_To',
        }

        monitoring::check_prometheus { "swift-${site}-media-uploads":
            description     => "mediawiki originals uploads (hourly) for ${site}",
            dashboard_links => ["https://grafana.wikimedia.org/d/OPgmB1Eiz/swift?panelId=26&fullscreen&orgId=1&var-DC=${site}"],
            query           => 'swift_container_stats_objects_total{class="originals"} - swift_container_stats_objects_total{class="originals"} offset 1h',
            warning         => 2000,
            critical        => 3000,
            method          => 'ge',
            prometheus_url  => "http://prometheus.svc.${site}.wmnet/ops",
            notes_link      => 'https://wikitech.wikimedia.org/wiki/Swift/How_To',
        }
    }

    # Percent difference in the number of mediawiki/thumbor objects in eqiad vs codfw
    monitoring::check_prometheus { 'mw-objects-diff-eqiad-codfw':
        description     => 'Number of mw swift objects in eqiad greater than codfw',
        dashboard_links => ['https://grafana.wikimedia.org/d/OPgmB1Eiz/swift?var-DC=eqiad'],
        # No temp containers, https://phabricator.wikimedia.org/T232448
        query           => 'swift_container_stats_objects_total{site="eqiad",class\!="temp"} / on(account, class) swift_container_stats_objects_total{site="codfw"}',
        warning         => 1.02,
        critical        => 1.05,
        method          => 'ge',
        # Icinga will query the site-local Prometheus 'global' instance
        prometheus_url  => "http://prometheus.svc.${::site}.wmnet/global",
    }

    monitoring::check_prometheus { 'mw-objects-diff-codfw-eqiad':
        description     => 'Number of mw swift objects in codfw greater than eqiad',
        dashboard_links => ['https://grafana.wikimedia.org/d/OPgmB1Eiz/swift?var-DC=codfw'],
        # No temp containers, https://phabricator.wikimedia.org/T232448
        query           => 'swift_container_stats_objects_total{site="codfw",class\!="temp"} / on(account, class) swift_container_stats_objects_total{site="eqiad"}',
        warning         => 1.02,
        critical        => 1.05,
        method          => 'ge',
        # Icinga will query the site-local Prometheus 'global' instance
        prometheus_url  => "http://prometheus.svc.${::site}.wmnet/global",
    }
}
