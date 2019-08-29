# == Define icinga::monitor::elasticsearch::old_jvm_gc_checks
define icinga::monitor::elasticsearch::old_jvm_gc_checks {
    # alert when GC operation hit 100 ops/hour
    $prom_name = "${::hostname}-${title}"
    monitoring::check_prometheus { "old_jvm_gc_${prom_name}":
        description     => "Old JVM GC check - ${prom_name}",
        dashboard_links => ['https://grafana.wikimedia.org/d/000000462/elasticsearch-memory?orgId=1'],
        query           => "scalar(rate(elasticsearch_jvm_gc_collection_seconds_count{exported_cluster=\"${title}\", gc=\"old\", name=\"${prom_name}\"}[1h]) * 3600)",
        prometheus_url  => "http://prometheus.svc.${::site}.wmnet/ops",
        method          => 'gt',
        critical        => 100,
        warning         => 80,
        contact_group   => 'admins,team-discovery',
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Search#Using_jstack_or_jmap_or_other_similar_tools_to_view_logs',
    }
}
