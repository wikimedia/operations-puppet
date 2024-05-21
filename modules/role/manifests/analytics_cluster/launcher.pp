# == Class role::analytics_cluster::launcher
#
class role::analytics_cluster::launcher {

    system::role { 'analytics_cluster::launcher':
        description => 'Analytics Cluster host launching jobs (airflow-analytics, Spark, Report Updater, etc..)'
    }

    include profile::java
    include profile::analytics::cluster::client

    include profile::hive::site_hdfs

    # Include analytics/refinery deployment target.
    include profile::analytics::refinery

    include profile::statistics::base

    include profile::hadoop::balancer

    include profile::statistics::dataset_mount

    # Include airflow instances as defined in role hiera.
    # launcher just runs the airflow-analytics instnace.
    include profile::airflow

    include profile::analytics::refinery_git_config
    include profile::analytics::refinery::job::import_mediawiki_dumps
    include profile::analytics::refinery::job::import_wikidata_entities_dumps
    include profile::analytics::refinery::job::import_commons_mediainfo_dumps
    include profile::analytics::refinery::job::data_check
    include profile::analytics::refinery::job::refine
    include profile::analytics::refinery::job::refine_sanitize
    # Camus is being replaced by Gobblin: T271232
    include profile::analytics::refinery::job::gobblin
    include profile::analytics::refinery::job::canary_events
    include profile::analytics::refinery::job::hdfs_cleaner
    include profile::analytics::refinery::job::project_namespace_map
    include profile::analytics::refinery::job::sqoop_mediawiki
    include profile::analytics::refinery::job::data_purge

    include profile::kerberos::client
    include profile::kerberos::keytabs

    include profile::base::production
    include profile::firewall
}
