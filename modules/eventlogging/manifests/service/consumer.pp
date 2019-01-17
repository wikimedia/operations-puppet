# == Define: eventlogging::service::consumer
#
# Consumers are data sinks; they act as an interface between
# EventLogging and various data storage, monitoring, and visualization
# systems. Multiple consumers may subscribe to a single event stream.
# One consumer may write the data to Hadoop, another to statsd, another
# to MySQL, etc. Both the input stream and the output medium are
# specified by URI. A plug-in architecture provides a mechanism for a
# plug-in to register itself as the handler of a particular output URI
# scheme (for example, the MySQL consumer handles "mysql://" URIs).
#
# === Parameters
#
# [*input*]
#   This parameter specifies the URI of the event stream the consumer
#   should consume. Example: 'tcp://eventlog1002.eqiad.wmnet:8600'.
#
# [*output*]
#   Bind the multiplexing publisher to this URI.
#   Example: 'tcp://*:8600'.
#
# [*sid*]
#   Specifies the Socket ID consumer should use to identify itself when
#   subscribing to the input stream. Defaults to the resource title.
#   Should contain only URL-safe characters.
#
# [*schemas_path*]
#   If given, this path will be passed to eventlogging-consumer --schemas-path,
#   which causes schemas to be loaded and cached from a local file path before
#   consumption begins.  This does not restrict the consumer from finding
#   schemas on meta.wikimedia.org if they don't exist in schemas_path.
#
# [*ensure*]
#   Specifies whether the consumer should be provisioned or destroyed.
#   Value may be 'present' (provisions the resource; the default) or
#   'absent' (destroys the resource).
#
# [*owner*]
#   Owner of config file.  Default: root
#
# [*group*]
#   Group owner of config file.  Default: root
#
# [*mode*]
#   File permission mode of config file.  Default: 0644
#
# [*reload_on]
#   Reload eventlogging-consumer if any of the provided Puppet
#   resources have changed.  This should be an array of alreday
#   declared puppet resources.  E.g.
#   [File['/path/to/topicconfig.yaml'], Class['::something::else']]
#
# === Examples
#
#  eventlogging::service::consumer { 'all events':
#    input  => 'tcp://eventlog1002.eqiad.wmnet:8600',
#    output => 'mysql://user:password@eventlog1002.eqiad.wmnet:3306/?charset=utf8',
#  }
#
define eventlogging::service::consumer(
    $input,
    $output,
    $sid          = $title,
    $schemas_path = undef,
    $ensure       = present,
    $owner        = 'root',
    $group        = 'root',
    $mode         = '0644',
    $reload_on    = undef,
) {

    Class['eventlogging::server'] -> Eventlogging::Service::Consumer[$title]

    # eventlogging will run out of the path configured in the
    # eventlogging::server class.
    $eventlogging_path = $eventlogging::server::eventlogging_path
    $eventlogging_log_dir = $eventlogging::server::log_dir
    $basename = regsubst($title, '\W', '-', 'G')
    $config_file = "/etc/eventlogging.d/consumers/${basename}"
    $service_name = "eventlogging-consumer@${basename}"
    $_log_file = "${eventlogging_log_dir}/${service_name}.log"

    file { $config_file:
        ensure  => $ensure,
        content => template('eventlogging/consumer.erb'),
        owner   => $owner,
        group   => $group,
        mode    => $mode,
    }

    rsyslog::conf { $service_name:
        content  => template('eventlogging/rsyslog.conf.erb'),
        priority => 80,
    }
    systemd::service { $service_name:
        ensure  => present,
        content => systemd_template('eventlogging-consumer@'),
        restart => true,
        require => File[$config_file],
    }
}
