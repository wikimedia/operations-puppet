# == Class role::analytics::hadoop::client
# Installs Hadoop client pacakges and configuration.
#
class role::analytics_new::hadoop::client {
    # need java before hadoop is installed
    require_package('openjdk-7-jdk')

    $hadoop_var_directory                     = '/var/lib/hadoop'
    $hadoop_name_directory                    = "${hadoop_var_directory}/name"
    $hadoop_data_directory                    = "${hadoop_var_directory}/data"
    $hadoop_journal_directory                 = "${hadoop_var_directory}/journal"

    # [WIP] Use hiera to configure Hadoop in labs.
    # You MUST set at least the following:
    #  cdh::hadoop::cluster_name
    #  cdh::hadoop::namenode_hosts
    #  cdh::hadoop::resourcemanager_hosts
    #
    class { 'cdh::hadoop':
        zookeeper_hosts                             => keys(hiera('zookeeper_hosts', undef)),
        datanode_mounts => [
            "${hadoop_data_directory}/a",
            "${hadoop_data_directory}/b",
        ],
        dfs_name_dir                                => [$hadoop_name_directory],
        dfs_journalnode_edits_dir                   => $hadoop_journal_directory,

        # Turn on Snappy compression by default for maps and final outputs
        mapreduce_intermediate_compression_codec    => 'org.apache.hadoop.io.compress.SnappyCodec',
        mapreduce_output_compression                => true,
        mapreduce_output_compression_codec          => 'org.apache.hadoop.io.compress.SnappyCodec',
        mapreduce_output_compression_type           => 'BLOCK',

        mapreduce_job_reuse_jvm_num_tasks           => 1,

        # This needs to be set in order to use Impala
        dfs_datanode_hdfs_blocks_metadata_enabled   => true,

        # Use fair-scheduler.xml.erb to define FairScheduler queues.
        fair_scheduler_template                     => 'role/analytics_new/hadoop/fair-scheduler.xml.erb',

        # Yarn App Master possible port ranges
        yarn_app_mapreduce_am_job_client_port_range => '55000-55199',

        yarn_site_extra_properties                  => {
            # Enable FairScheduler preemption. This will allow the essential queue
            # to preempt non-essential jobs.
            'yarn.scheduler.fair.preemption'              => true,
            # Let YARN wait for at least 1/3 of nodes to present scheduling
            # opportunties before scheduling a job for certain data
            # on a node on which that data is not present.
            'yarn.scheduler.fair.locality.threshold.node' => '0.33',
            # After upgrading to CDH 5.4.0, we are encountering this bug:
            # https://issues.apache.org/jira/browse/MAPREDUCE-5799
            # This should work around the problem.
            'yarn.app.mapreduce.am.env'                   => 'LD_LIBRARY_PATH=/usr/lib/hadoop/lib/native',
            # The default of 90.0 for this was marking older dells as unhealthy when they still
            # had 2TB of space left.  99% will mark them at unhealthy with they still have
            # > 200G free.
            'yarn.nodemanager.disk-health-checker.max-disk-utilization-per-disk-percentage' => '99.0',
        },
    }

    # If in production AND the current node is a journalnode, then
    # go ahead and include an icinga alert for the JournalNode process.
    if $::realm == 'production' and member($journalnode_hosts, $::fqdn) {
        nrpe::monitor_service { 'hadoop-hdfs-journalnode':
            description  => 'Hadoop JournalNode',
            nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a "org.apache.hadoop.hdfs.qjournal.server.JournalNode"',
            require      => Class['cdh::hadoop'],
            critical     => true,
        }
    }

    file { '/usr/local/bin/hadoop-yarn-logging-helper.sh':
        content => template('hadoop/hadoop-yarn-logging-helper.erb'),
        mode    => '0744',
    }
    if $::cdh::hadoop::gelf_logging_enabled {
        ensure_packages([
            # library dependency
            'libjson-simple-java',
            # the libary itself: logstash-gelf.jar
            'liblogstash-gelf-java',
        ])
        # symlink into hadoop classpath
        file { '/usr/lib/hadoop/lib/json_simple.jar':
            ensure  => 'link',
            target  => '/usr/share/java/json_simple.jar',
            require => Package['libjson-simple-java'],
        }

        # symlink into hadoop classpath
        file { '/usr/lib/hadoop/lib/logstash-gelf.jar':
            ensure  => 'link',
            target  => '/usr/share/java/logstash-gelf.jar',
            require => Package['liblogstash-gelf-java'],
        }
        # Patch container-log4j.properties inside nodemanager jar
        # See script source for details
        exec { 'hadoop-yarn-logging-helper-set':
            command   => '/usr/local/bin/hadoop-yarn-logging-helper.sh set',
            subscribe => File['/usr/local/bin/hadoop-yarn-logging-helper.sh'],
        }
    } else {
        # Revert to original unmodified jar
        exec { 'hadoop-yarn-logging-helper-reset':
            command   => '/usr/local/bin/hadoop-yarn-logging-helper.sh reset',
            subscribe => File['/usr/local/bin/hadoop-yarn-logging-helper.sh'],
        }
    }

    # Install MaxMind databases for geocoding UDFs
    include geoip

    # Install packages that are useful for distributed
    # computation in Hadoop, and thus should be available on
    # any Hadoop nodes.
    require_package(
        # Need python3 on Hadoop nodes in order to run
        # Hadoop Streaming python jobs.
        'python3',
        'python-numpy',
        'python-pandas',
        'python-scipy',
        'python-requests',
        'python-matplotlib',
        'python-dateutil',
        'python-sympy',
    )


    if $::realm == 'labs' {
        # Hadoop directories in labs should be created by puppet.
        # This conditional could be added to each worker,master,standby
        # classes, but since it doesn't hurt to have these directories
        # in labs, and since I don't want to add the $::realm conditionals
        # in each class, I do it here.
        file { [
            $hadoop_var_directory,
            $hadoop_data_directory,
        ]:
            ensure => 'directory',
        }
    }
}
