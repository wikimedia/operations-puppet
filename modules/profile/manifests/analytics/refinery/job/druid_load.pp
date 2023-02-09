# SPDX-License-Identifier: Apache-2.0
# == Class profile::analytics::refinery::job::druid_load
#
# Installs spark jobs to load data sets to Druid.
#
class profile::analytics::refinery::job::druid_load(
    Wmflib::Ensure $ensure_timers = lookup('profile::analytics::refinery::job::druid_load::ensure_timers', { 'default_value' => 'present' }),
) {
    require ::profile::analytics::refinery

    # Update this when you want to change the version of the refinery job jar
    # being used for the druid load jobs.
    $refinery_version = '0.0.146'

    # Use this value as default refinery_job_jar.
    Profile::Analytics::Refinery::Job::Eventlogging_to_druid_job {
        ensure           => $ensure_timers,
        refinery_job_jar => "${::profile::analytics::refinery::path}/artifacts/org/wikimedia/analytics/refinery/refinery-job-${refinery_version}.jar"
    }

    # Load event.netflow
    # Note that this data set does not belong to EventLogging, but the
    # eventlogging_to_druid_job wrapper is compatible and very convenient!
    profile::analytics::refinery::job::eventlogging_to_druid_job { 'netflow':
        job_config        => {
            database         => 'event',
            druid_datasource => 'wmf_netflow',
            timestamp_column => 'stamp_inserted',
            dimensions       => 'as_dst,as_path,peer_as_dst,as_src,ip_dst,ip_proto,ip_src,peer_as_src,port_dst,port_src,tag2,tcp_flags,country_ip_src,country_ip_dst,peer_ip_src,parsed_comms,net_cidr_src,net_cidr_dst,as_name_src,as_name_dst,ip_version,region',
            metrics          => 'bytes,packets',
        },
        # settings copied from webrequest_sampled_128 load job
        # as data-size is similar
        hourly_shards     => 4,
        hourly_reduce_mem => '8192',
        daily_shards      => 32,
    }
    # This second round serves as sanitization, after 90 days of data loading.
    # Note that some dimensions are not present, thus nullifying their values.
    profile::analytics::refinery::job::eventlogging_to_druid_job { 'netflow-sanitization':
        ensure_hourly    => 'absent',
        daily_days_since => 61,
        daily_days_until => 60,
        daily_shards     => 2,
        job_config       => {
            database         => 'event',
            table            => 'netflow',
            druid_datasource => 'wmf_netflow',
            timestamp_column => 'stamp_inserted',
            dimensions       => 'as_dst,as_path,peer_as_dst,as_src,ip_proto,tag2,country_ip_src,country_ip_dst,parsed_comms,as_name_src,as_name_dst,ip_version,region',
            metrics          => 'bytes,packets',
        },
    }

    # Load event.network_flows_internal
    # Note that this data set does not belong to EventLogging, but the
    # eventlogging_to_druid_job wrapper is compatible and very convenient!
    profile::analytics::refinery::job::eventlogging_to_druid_job { 'network_flows_internal':
        job_config        => {
            database         => 'event',
            druid_datasource => 'network_flows_internal',
            timestamp_column => 'stamp_inserted',
            dimensions       => 'ip_dst,ip_proto,ip_src,port_dst,port_src,peer_ip_src,ip_version,region',
            metrics          => 'bytes,packets',
        },
        # settings copied from webrequest_sampled_128 load job
        # as data-size is similar
        hourly_shards     => 1,
        hourly_reduce_mem => '8192',
        daily_shards      => 1,
    }
    # This second round serves as sanitization, after 90 days of data loading.
    # Note that some dimensions are not present, thus nullifying their values.
    profile::analytics::refinery::job::eventlogging_to_druid_job { 'network_flows_internal-sanitization':
        # This sanitization job runs on 60 days old data and fails when there is no input data
        # Absenting the job until 2022-03-21
        ensure           => 'absent',
        ensure_hourly    => 'absent',
        daily_days_since => 61,
        daily_days_until => 60,
        daily_shards     => 2,
        job_config       => {
            database         => 'event',
            table            => 'network_flows_internal',
            druid_datasource => 'network_flows_internal',
            timestamp_column => 'stamp_inserted',
            dimensions       => 'ip_proto,ip_version,region',
            metrics          => 'bytes,packets',
        },
    }
}
