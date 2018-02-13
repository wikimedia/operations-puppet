# Define various checks for Maps
class profile::maps::alerts {
    monitoring::check_prometheus { 'maps-osm-sync-lag-eqiad':
      description     => 'Maps - OSM synchronization lag - eqiad',
      dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/maps-performances?panelId=11&fullscreen&orgId=1'],
      query           => 'scalar(max(time()-osm_sync_timestamp{cluster="maps"}))',
      warning         => 25 * 3600, # 25 hours
      critical        => 48 * 3600, # 48 hours
      prometheus_url  => 'http://prometheus.svc.eqiad.wmnet/ops',
    }
    monitoring::check_prometheus { 'maps-osm-sync-lag-codf':
        description     => 'Maps - OSM synchronization lag - codfw',
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/maps-performances?panelId=12&fullscreen&orgId=1'],
        query           => 'scalar(max(time()-osm_sync_timestamp{cluster="maps"}))',
        warning         => 25 * 3600, # 25 hours
        critical        => 48 * 3600, # 48 hours
        prometheus_url  => 'http://prometheus.svc.codfw.wmnet/ops',
    }
    monitoring::check_prometheus { 'maps-test-osm-sync-lag-codfw':
        description     => 'Maps (test) - OSM synchronization lag - codfw',
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/maps-performances?panelId=12&fullscreen&orgId=1'],
        query           => 'scalar(max(time()-osm_sync_timestamp{cluster="maps-test"}))',
        warning         => 25 * 3600, # 25 hours
        critical        => 48 * 3600, # 48 hours
        prometheus_url  => 'http://prometheus.svc.codfw.wmnet/ops',
    }
}
