# SPDX-License-Identifier: Apache-2.0
# Define various checks for Maps
class profile::maps::alerts(
    Stdlib::HTTPUrl $graphite_url = lookup('graphite_url'),
){

    monitoring::graphite_threshold { 'tilerator-tile-generation':
        description     => 'Maps tiles generation',
        dashboard_links => ['https://grafana.wikimedia.org/d/000000305/maps-performances?orgId=1&viewPanel=8'],
        metric          => 'transformNull(sumSeries(tilerator.gen.*.*.*.done.sample_rate),0)',
        # Tilerator should be generating tiles at least 2 hours per day
        # Values need to be adjusted if synchronization frequency is changed
        under           => true,
        warning         => 10,
        critical        => 5,
        from            => '1day',
        percentage      => 90,
        graphite_url    => $graphite_url,
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Maps/Runbook',
    }

    monitoring::check_prometheus { 'maps-osm-sync-lag-eqiad':
      description     => 'Maps - OSM synchronization lag - eqiad',
      dashboard_links => ['https://grafana.wikimedia.org/d/000000305/maps-performances?orgId=1&viewPanel=11'],
      query           => 'scalar(max(time()-osm_sync_timestamp{cluster="maps"}))',
      warning         => 49 * 3600, # 49 hours
      critical        => 3 * 24 * 3600, # 3 days
      prometheus_url  => 'http://prometheus.svc.eqiad.wmnet/ops',
      notes_link      => 'https://wikitech.wikimedia.org/wiki/Maps/Runbook',
    }
    monitoring::check_prometheus { 'maps-osm-sync-lag-codf':
        description     => 'Maps - OSM synchronization lag - codfw',
        dashboard_links => ['https://grafana.wikimedia.org/d/000000305/maps-performances?orgId=1&viewPanel=12'],
        query           => 'scalar(max(time()-osm_sync_timestamp{cluster="maps"}))',
        warning         => 49 * 3600, # 49 hours
        critical        => 3 * 24 * 3600, # 3 days
        prometheus_url  => 'http://prometheus.svc.codfw.wmnet/ops',
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Maps/Runbook',
    }
}
