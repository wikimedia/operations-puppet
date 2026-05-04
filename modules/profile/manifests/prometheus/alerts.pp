# SPDX-License-Identifier: Apache-2.0
# == Class: profile::prometheus::alerts
#
# Install icinga alerts based on Prometheus metrics.
# NOTE to be included only from one host, icinga will generate different alerts
# for all hosts that include this class.
#
class profile::prometheus::alerts (
    Array[String] $datacenters = lookup('datacenters'),
) {

    # Monitor throughput and dropped messages on MirrorMaker instances.
    # main-eqiad -> jumbo MirrorMaker
    profile::kafka::mirror::alerts { 'main-eqiad-to-jumbo-eqiad':
        #  For now, alert Data Platform SREs.  Change this back to admins soon.
        contact_group         => 'team-data-platform',
        topic_blacklist       => '.*(change-prop|\.job\.|changeprop).*',
        prometheus_url        => 'http://prometheus.svc.eqiad.wmnet/ops',
        source_prometheus_url => 'http://prometheus.svc.eqiad.wmnet/ops',
    }

    # Cross DC main-eqiad <-> main-codfw MirrorMakers.
    profile::kafka::mirror::alerts { 'main-eqiad-to-main-codfw':
        prometheus_url        => 'http://prometheus.svc.codfw.wmnet/ops',
        source_prometheus_url => 'http://prometheus.svc.eqiad.wmnet/ops',
    }
    # main-eqiad is getting the bulk of the traffic from MediaWiki,
    # and it currently pulls msgs from main-codfw at a very low rate
    # (but we want to make sure that it doesn't drop to zero).
    profile::kafka::mirror::alerts { 'main-codfw-to-main-eqiad':
        #  For now, alert analytics admins, until alerts are more stable.
        prometheus_url        => 'http://prometheus.svc.eqiad.wmnet/ops',
        source_prometheus_url => 'http://prometheus.svc.codfw.wmnet/ops',
        warning_throughput    => 3,
    }

    ### The same as previous ones, but fully Prometheus-based

    # Monitor throughput and dropped messages on MirrorMaker instances.
    # main-eqiad -> jumbo MirrorMaker
    profile::kafka::mirror::prometheus_alerts { 'main-eqiad-to-jumbo-eqiad':
        #  For now, alert Data Platform SREs.  Change this back to admins soon.
        team                   => 'data-platform',
        topic_blacklist        => '.*(change-prop|\\\\.job\\\\.|changeprop).*',
        prometheus_site        => 'eqiad',
        source_prometheus_site => 'eqiad',
    }

    # Cross DC main-eqiad <-> main-codfw MirrorMakers.
    profile::kafka::mirror::prometheus_alerts { 'main-eqiad-to-main-codfw':
        prometheus_site        => 'codfw',
        source_prometheus_site => 'eqiad',
    }
    # main-eqiad is getting the bulk of the traffic from MediaWiki,
    # and it currently pulls msgs from main-codfw at a very low rate
    # (but we want to make sure that it doesn't drop to zero).
    profile::kafka::mirror::prometheus_alerts { 'main-codfw-to-main-eqiad':
        #  For now, alert analytics admins, until alerts are more stable.
        prometheus_site        => 'eqiad',
        source_prometheus_site => 'codfw',
        warning_throughput     => 3,
    }
}
