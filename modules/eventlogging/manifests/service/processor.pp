# == Define: eventlogging::service::processor
#
# EventLogging processors transform a raw request log, such as might be
# generated by Varnish or MediaWiki, into a well-structured stream of
# JSON events.
#
# === Parameters
#
# [*format*]
#   scanf-like format string, specifying the layout of EventLogging
#   fields in raw log records. The available format specifiers are:
#
#     %h       Client IP
#     %j       JSON object
#     %q       Query-string-encoded JSON
#     %t       Timestamp in NCSA format
#     %{..}i   Tab-delimited string
#     %{..}s   Space-delimited string
#     %{..}d   Integer
#
#   (Where '..' is the desired property name for the matching group.)
#
#   All other parts of the format string are interpreted as Python
#   regexp syntax. See <http://docs.python.org/2/library/re.html>
#   for details.
#
# [*input*]
#   The URI of the raw log stream which the processor will take as its
#   input. Example: 'tcp://eventlog1001.eqiad.wmnet:8421'.
#
# [*outputs*]
#   An array of URIs to output to. Example: [
#       'tcp://eventlog1001.eqiad.wmnet:8521',
#       'kafka:///localhost:9092?topic=eventlogging_%s(schema)s'
#   ]
#
# [*output_invalid*]
#   An optional URI specifying the interface and port on which the invalid
#   event stream will be published. Example: 'tcp://*:8601'. Defaults to
#   null.  If set to true, then eventlogging will choose the first
#   output URI in the outputs array.
#
# [*sid*]
#   Specifies the socket ID the processor will use to identify itself
#   when subscribing to input streams. Defaults to the resource title.
#
# [*ensure*]
#   If 'present' (the default), sets up the processor. If 'absent',
#   destroys it.
#
# === Examples
#
#  eventlogging::service::processor { 'client_side_events':
#    input  => 'tcp://127.0.0.1:8422',
#    format => '%q %l %n %t %h',
#    output => 'tcp://*:8522',
#  }
#
define eventlogging::service::processor(
    $format,
    $input,
    $outputs,
    $output_invalid = undef,
    $sid            = $title,
    $ensure         = present,
) {
    Class['eventlogging::server'] -> Eventlogging::Service::Processor[$title]

    # eventlogging will run out of the path configured in the
    # eventlogging::server class.
    $eventlogging_path = $eventlogging::server::eventlogging_path
    $eventlogging_log_dir = $eventlogging::server::log_dir
    $basename = regsubst($title, '\W', '-', 'G')
    $config_file = "/etc/eventlogging.d/processors/${basename}"
    $service_name = "eventlogging-processor@${basename}"
    $_log_file = "${eventlogging_log_dir}/${service_name}.log"

    file { $config_file:
        ensure  => $ensure,
        content => template('eventlogging/processor.erb'),
    }

    if os_version('debian >= stretch') {
        rsyslog::conf { $service_name:
            content  => template('eventlogging/rsyslog.conf.erb'),
            priority => 80,
        }
        systemd::service { $service_name:
            ensure  => present,
            content => systemd_template('eventlogging-processor@'),
            restart => true,
            require => File[$config_file],
        }
    }
}
