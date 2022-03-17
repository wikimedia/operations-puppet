# == Class profile::analytics::refinery::job::test::gobblin
# Declares gobblin jobs to import data from Kafka into Hadoop.
# (Gobblin is a replacement for Camus).
#
# These jobs will eventually be moved to Airflow.
#
# == Parameters
#
# [*gobblin_jar_file*]
#   Path to shaded jar that will be used to launch gobblin.
#   You should set this in your role hiera to a versioned gobblin-wmf jar.
#   Usually this is deployed alongside of analytics/refinery artifacts.
#
class profile::analytics::refinery::job::test::gobblin(
    Stdlib::Unixpath $gobblin_jar_file = lookup('profile::analytics::refinery::job::test::gobblin_jar_file'),
) {
    require ::profile::analytics::refinery
    $refinery_path = $::profile::analytics::refinery::path

    # analytics-test-hadoop gobblin jobs should all use analytics-test-hadoop.sysconfig.properties.
    Profile::Analytics::Refinery::Job::Gobblin_job {
        sysconfig_properties_file => "${refinery_path}/gobblin/common/analytics-test-hadoop.sysconfig.properties",
        gobblin_jar_file          => $gobblin_jar_file,
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
