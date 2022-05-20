# == Class icinga::monitor::elasticsearch::cirrus_cluster_checks
class icinga::monitor::elasticsearch::cirrus_cluster_checks(
    Integer $shard_size_warning,
    Integer $shard_size_critical,
    String $threshold,
    Integer $timeout,
){
    $ports = [9243, 9443, 9643]
    $sites = ['eqiad', 'codfw']
    $scheme = 'https'

    $sites.each |$site| {
        $host = "search.svc.${site}.wmnet"

        # Create the Icinga host for search.
        # The service::catalog integration used to create these hosts
        # automatically via 'monitoring' section (now deprecated).
        # See also https://phabricator.wikimedia.org/T291946
        @monitoring::host { $host:
            ip_address    => ipresolve($host, 4),
            contact_group => 'admins',
            group         => 'lvs',
            critical      => false,
        }

        icinga::monitor::elasticsearch::base_checks { $host:
            host                => $host,
            scheme              => $scheme,
            ports               => $ports,
            shard_size_warning  => $shard_size_warning,
            shard_size_critical => $shard_size_critical,
            timeout             => $timeout,
            threshold           => $threshold,
        }

        icinga::monitor::elasticsearch::cirrus_checks { $host:
            host   => $host,
            scheme => $scheme,
            ports  => $ports,
        }

        # this is checking for update rate over the last 60 minutes. Ideally, we'd like a shorter window for this
        # check, but T224425 makes it generate too much noise.
        # FIXME: reduce moving average to 10 minutes once T224425 is fixed.
        monitoring::graphite_threshold { "mediawiki_cirrus_update_rate_${site}":
            description     => "Mediawiki CirrusSearch update rate - ${site}",
            dashboard_links => ['https://grafana.wikimedia.org/d/JLK3I_siz/elasticsearch-indexing?panelId=44&fullscreen&orgId=1'],
            host            => $host,
            metric          => "movingAverage(transformNull(MediaWiki.CirrusSearch.${site}.updates.all.sent.rate),\"60minutes\")",
            warning         => 80,
            critical        => 50,
            under           => true,
            contact_group   => 'admins,team-discovery',
            notes_link      => 'https://wikitech.wikimedia.org/wiki/Search#No_updates',
        }
    }

    # Search is currently too busy - T262694
    monitoring::graphite_threshold { 'mediawiki_cirrus_pool_counter_rejections_rate':
        description     => 'Mediawiki CirrusSearch pool counter rejections rate',
        dashboard_links => ['https://grafana.wikimedia.org/d/qrOStmdGk/elasticsearch-pool-counters?viewPanel=4&orgId=1'],
        metric          => "aliasByNode(sum(movingAverage(consolidateBy(transformNull(MediaWiki.CirrusSearch.poolCounter.*.failureMs.sample_rate, 0), \"max\"), \"5minutes\")), 1, 2)",
        warning         => 500,
        critical        => 1000,
        contact_group   => 'admins,team-discovery',
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Search#Pool_Counter_rejections_(search_is_currently_too_busy)',
    }

    # Background repair process finding lots of bad documents - T295365
    monitoring::graphite_threshold { 'mediawiki_cirrussearch_indices_high_fix_rate':
        description     => 'Mediawiki CirrusSearch Saneitizer Weekly Fix Rate',
        dashboard_links => ['https://grafana.wikimedia.org/d/JLK3I_siz/elasticsearch-indexing?viewPanel=35&orgId=1&from=now-6M&to=now'],
        metric          => 'smartSummarize(transformNull(MediaWiki.CirrusSearch.{eqiad,codfw,cloudelastic}.sanitization.fixed.sum, 0), "1wk", "sum")',
        warning         => 100000,
        critical        => 250000,
        contact_group   => 'admins,team-discovery',
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Search#Saneitizer_(background_repair_process)',
    }
}
