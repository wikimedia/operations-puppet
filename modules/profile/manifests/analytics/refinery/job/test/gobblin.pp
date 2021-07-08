# == Class profile::analytics::refinery::job::test::gobblin
# Declares gobblin jobs to import data from Kafka into Hadoop.
# (Gobblin is a replacement for Camus).
#
# These jobs will eventually be moved to Airflow.
#
class profile::analytics::refinery::job::test::gobblin {
    require ::profile::analytics::refinery
    $refinery_path = $::profile::analytics::refinery::path

    # analytics-test-hadoop gobblin jobs should all use analytics-test-hadoop.sysconfig.properties.
    Profile::Analytics::Refinery::Job::Gobblin_job {
        sysconfig_properties_file => "${refinery_path}/gobblin/common/analytics-test-hadoop.sysconfig.properties"
    }

    profile::analytics::refinery::job::gobblin_job { 'webrequest_test':
        interval         => '*-*-* *:00/10:00',
    }

    profile::analytics::refinery::job::gobblin_job { 'eventlogging_legacy_test':
        interval         => '*-*-* *:05:00',
    }
}