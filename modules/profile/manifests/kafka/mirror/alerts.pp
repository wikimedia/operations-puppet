# SPDX-License-Identifier: Apache-2.0
# == Class profile::kafka::mirror::alerts
# Sets up fully Prometheus/Alertmanager based alert rules for MirrorMaker.
# A previous attempt to move alerts directly to the alerts
# repo was already made, but given the complexity, they've been
# configured here to leverage puppet templating.
# See also: https://gerrit.wikimedia.org/r/c/operations/alerts/+/1077986
#
class profile::kafka::mirror::alerts() {
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
