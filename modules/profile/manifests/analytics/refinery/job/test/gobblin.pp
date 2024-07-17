# SPDX-License-Identifier: Apache-2.0
# == Class profile::analytics::refinery::job::test::gobblin
# Declares gobblin jobs to import data from Kafka into Hadoop.
# (Gobblin is a replacement for Camus).
#
# These jobs will eventually be moved to Airflow.
#
# == Parameters
#
# [*gobblin_wmf_version*]
#   gobblin-wmf-core version to use.  This will be used to infer the gobblin_wmf_jar path
#   to use out of the analytics/refinery/artifacts directory.
#
# [*ensure_timers*]
#   This parameter can be used to disable gobblin test jobs, effectively pausing
#   ingestion to Hadoop. This might be necessary for short periods, such as
#   during HDFS maintenance work
#
class profile::analytics::refinery::job::test::gobblin(
    String $gobblin_wmf_version = lookup('profile::analytics::refinery::job::test::gobblin_wmf_version', { 'default_value' => '1.0.2' }),
    String $ensure_timers = lookup('profile::analytics::refinery::job::test::gobblin::ensure_timers', { 'default_value' => 'present' }),
) {
    require ::profile::analytics::refinery
    $refinery_path = $::profile::analytics::refinery::path

    # analytics-test-hadoop gobblin jobs should all use analytics-test-hadoop.sysconfig.properties.
    Profile::Analytics::Refinery::Job::Gobblin_job {
        sysconfig_properties_file => "${refinery_path}/gobblin/common/analytics-test-hadoop.sysconfig.properties",
        gobblin_jar_file          => "${refinery_path}/artifacts/org/wikimedia/gobblin-wmf/gobblin-wmf-core-${gobblin_wmf_version}-jar-with-dependencies.jar"
    }

    profile::analytics::refinery::job::gobblin_job { 'webrequest_test':
        interval         => '*-*-* *:00/10:00',
    }

    profile::analytics::refinery::job::gobblin_job { 'event_default_test':
        interval         => '*-*-* *:05:00',
    }

    profile::analytics::refinery::job::gobblin_job { 'eventlogging_legacy_test':
        interval         => '*-*-* *:10:00',
    }
}
