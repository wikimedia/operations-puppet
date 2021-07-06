# == Class profile::analytics::refinery::job::gobblin
# Declares gobblin jobs to import data from Kafka into Hadoop.
# (Gobblin is a replacement for Camus).
#
# These jobs will eventually be moved to Airflow.
#
class profile::analytics::refinery::job::gobblin {
    require ::profile::analytics::refinery
    $refinery_path = $::profile::analytics::refinery::path

    # analytics-hadoop gobblin jobs should all use analytics-hadoop.sysconfig.properties.
    Profile::Analytics::Refinery::Job::Gobblin_job {
        sysconfig_properties_file => "${refinery_path}/gobblin/common/analytics-hadoop.sysconfig.properties"
    }

    # Will declare a job using ${refinery_path}/gobblin/jobs/webrequest.pull
    profile::analytics::refinery::job::gobblin_job { 'webrequest':
        interval         => '*-*-* *:00/10:00',
    }


    profile::analytics::refinery::job::gobblin_job { 'netflow':
        interval         => '*-*-* *:00/30:00',
    }

}