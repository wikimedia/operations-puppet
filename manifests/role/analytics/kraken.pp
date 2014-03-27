# kraken.pp - role classes dealing with Kraken data analysis.

# == Class role::analytics::kraken
# Kraken refers to the Analytics codebase used to generate
# analytics for WMF.
class role::analytics::kraken {
    # Need Hadoop client classes included to use Kraken.
    include role::analytics::clients

    # We want to be able to geolocate IP addresses
    include geoip
    # udp-filter is a useful thing!
    include misc::udp2log::udp_filter

    # many Kraken python scripts use docopt for CLI parsing.
    package { 'python-docopt':
        ensure => 'installed',
    }

    # Many kraken jobs use dclass for
    # User Agent Device classification
    package { 'libdclass-java':
        ensure  => 'installed',
    }

    # Include Kraken repository deployment target.
    deployment::target { 'analytics-kraken': }
    # kraken repository is deployed via git deploy into here.
    # You must deploy this yourself, puppet will not do it for you.
    $path = '/srv/deployment/analytics/kraken'

    # Path in HDFS in which external data should be imported.
    $external_data_hdfs_dir = '/wmf/data/external'

    # Create directory in /var/log for general purpose Kraken job logging.
    $log_dir = '/var/log/kraken'
    file { $log_dir:
        ensure => 'directory',
        owner  => 'root',
        group  => 'stats',
        # setgid bit here to make kraken log files writeable
        # by users in the stats group.
        mode   => '2775',
    }

}

# == Class role::analytics::kraken::jobs::import::webrequest
# Submits Camus MapReduce job hourly to import
# webrequest logs from Kafka.
class role::analytics::kraken::jobs::import::webrequest {
    require role::analytics::kraken

    $camus_jar        = "${::role::analytics::kraken::path}/lib/camus.jar"
    $camus_properties = "${::role::analytics::kraken::path}/kraken-etl/conf/camus.webrequest.properties"
    $camus_log_file   = "${::role::analytics::kraken::log_dir}/camus-webrequest-import.log"

    cron { 'kraken-import-hourly-webrequests':
        command => "${::role::analytics::kraken::path}/kraken-etl/camus --job-name camus-webrequest-import ${camus_properties} >> ${camus_log_file} 2>&1",
        user    => 'hdfs',  # we might want to use a different user for this, not sure.
        minute  => 8,
    }
}

# == Class role::analytics::kraken::import::pagecounts
# Handles importing of hourly pagecount statistics into
# HDFS and creating Hive partition tables.
class role::analytics::kraken::jobs::import::pagecounts {
    include role::analytics::kraken

    $script      = "${role::analytics::kraken::path}/kraken-etl/pagecount-importer"
    $datadir     = $role::analytics::kraken::external_data_hdfs_dir

    # Don't attempt to import anything before this date.
    # This imports everything since August 1 2013.
    $start_date  = '2013.07.31_23'

    # Note:  I'm not worried about logrotate yet.
    # This generates just a few lines per hour.
    $log_file     = "${role::analytics::kraken::log_dir}/pagecount-importer.log"

    # make sure the script has been deployed.
    exec { "${script}-exists":
        command => "/usr/bin/test -f ${script}",
        # This exec doesn't actually create $script, but
        # we don't need to run test -f it puppet can already
        # tell that the file exists.
        creates => $script,
    }

    # cron job to download any missing pagecount files from
    # dumps.wikimedia.org and store them into HDFS.
    cron { 'kraken-import-hourly-pagecounts':
        command => "${script} --start ${start_date} ${datadir} >> ${log_file} 2>&1",
        user    => 'hdfs',
        minute  => 5,
        require => Exec["${script}-exists"],
    }
}

# == Class role::analytics::kraken::hive::partitions::external
# Installs cron job that creates external Hive partitions for imported
# datasets in $external_data_hdfs_dir.
class role::analytics::kraken::jobs::hive::partitions::external {
    include role::analytics::kraken

    $script      = "${role::analytics::kraken::path}/kraken-etl/hive-partitioner"
    $datadir     = $role::analytics::kraken::external_data_hdfs_dir
    $database    = 'wmf'

    # Note:  I'm not worried about logrotate yet.
    # This generates just a few lines per hour.
    $log_file    = "${role::analytics::kraken::log_dir}/hive-partitioner.log"

    # make sure the script has been deployed.
    exec { "${script}-exists":
        command => "/usr/bin/test -x ${script}",
        # This exec doesn't actually create $script, but
        # we don't need to run test it puppet can already
        # tell that the file exists.
        creates => $script,
    }


    # Use hcatalog jar for JsonSerDe
    $hive_options = '--auxpath /usr/lib/hcatalog/share/hcatalog/hcatalog-core-0.5.0-cdh4.3.1.jar'
    # cron job to automatically create hive partitions for any
    # newly imported data.
    cron { 'kraken-create-external-hive-partitions':
        command => "${script} --database ${database} --hive-options='${hive_options}' ${datadir} >> ${log_file} 2>&1",
        user    => 'hdfs',
        minute  => 15,
        require => Exec["${script}-exists"],
    }
}