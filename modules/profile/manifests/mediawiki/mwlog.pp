class profile::mediawiki::mwlog (
  Stdlib::Unixpath $log_directory = lookup('profile::mediawiki::mwlog::log_directory', {'default_value' => '/srv/mw-log-kafka'}),
  Optional[Stdlib::Fqdn] $primary_host = lookup('profile::mediawiki::mwlog::primary_host', {'default_value' => undef}),
  Optional[Stdlib::Fqdn] $standby_host = lookup('profile::mediawiki::mwlog::standby_host', {'default_value' => undef}),
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

    # use logrotate >= 3.21.0 backported from bookworm on mwlog hosts
    if debian::codename::eq('bullseye') {
        apt::package_from_component { 'logrotate':
            component => 'component/logrotate',
            priority  => 1002,
        }
    }

    kafkatee::instance { 'mwlog':
        kafka_brokers   => $kafka_config['brokers']['ssl_array'],
        output_encoding => 'json',
        inputs          => $mwlog_inputs,
        ssl_enabled     => true,
        ssl_ca_location => profile::base::certificates::get_trusted_ca_path(),
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
        post_rotate  => ['service kafkatee-mwlog reload'],
    }

    if $primary_host and $standby_host {
        rsync::quickdatacopy { 'srv-mw-log':
            source_host          => $primary_host,
            dest_host            => $standby_host,
            auto_sync            => false,
            module_path          => '/srv/mw-log',
            server_uses_stunnel  => true,
            use_generic_firewall => true,
        }
    }
}
