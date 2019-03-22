class profile::mediawiki::mwlog (
  $log_directory = hiera('profile::mediawiki::mwlog::log_directory', '/srv/mw-log-kafka'),
) {
    $kafka_config = kafka_config('logging-eqiad')
    $topic_prefix = 'mwlog-'
    # NOTE needs to be updated when adding/removing partitions from topics
    $partitions = '0-2'

    $archive_directory = "${log_directory}/archive"
    file { [$log_directory, $archive_directory]:
        ensure  => 'directory',
        owner   => 'kafkatee',
        group   => 'kafkatee',
        require => Package['kafkatee'],
    }

    file { '/usr/local/bin/mwlog-demux.py':
        ensure => present,
        source => 'puppet:///modules/profile/mediawiki/mwlog/mwlog-demux.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    $mwlog_levels = ['debug', 'err', 'info', 'notice', 'warning']
    $mwlog_inputs = $mwlog_levels.map |String $level| {
      {
        'topic'      => "${topic_prefix}${level}",
        'partitions' => $partitions,
        'options'    => { 'encoding' => 'json' },
        'offset'     => 'end',
      }
    }

    kafkatee::instance { 'mwlog':
        kafka_brokers   => $kafka_config['brokers']['array'],
        output_encoding => 'json',
        inputs          => $mwlog_inputs,
    }

    kafkatee::output { 'udp2log-compat':
        instance_name => 'mwlog',
        destination   => "/usr/local/bin/mwlog-demux.py --basedir ${log_directory}",
        type          => 'pipe',
    }

    logrotate::rule { 'udp2log-compat':
        ensure       => present,
        file_glob    => "${log_directory}/*.log",
        old_dir      => "${log_directory}/archive",
        frequency    => 'daily',
        not_if_empty => true,
        no_create    => true,
        max_age      => 90,
        date_ext     => true,
        compress     => true,
        missing_ok   => true,
        post_rotate  => 'service kafkatee-mwlog reload',
    }
}
