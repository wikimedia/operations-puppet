# == Define: eventlogging::service::consumer
#
# Consumers are data sinks; they act as an interface between
# EventLogging and various data storage, monitoring, and visualization
# systems. Multiple consumers may subscribe to a single event stream.
# One consumer may write the data to Hadoop, another to statsd, another
# to MongoDB, etc. Both the input stream and the output medium are
# specified by URI. A plug-in architecture provides a mechanism for a
# plug-in to register itself as the handler of a particular output URI
# scheme (for example, the MongoDB consumer handles "mongo://" URIs).
#
# === Parameters
#
# [*input*]
#   This parameter specifies the URI of the event stream the consumer
#   should consume. Example: 'tcp://eventlog1001.eqiad.wmnet:8600'.
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
# === Examples
#
#  eventlogging::service::consumer { 'all events':
#    input  => 'tcp://eventlog1001.eqiad.wmnet:8600',
#    output => 'mongodb://eventlog1001.eqiad.wmnet:27017/?w=1',
#  }
#
define eventlogging::service::consumer(
    $input,
    $output,
    $sid    = $title,
    $ensure = present,
    $owner  = 'root',
    $group  = 'root',
    $mode   = '0644',
) {
    include ::eventlogging

    $basename = regsubst($title, '\W', '-', 'G')
    file { "/etc/eventlogging.d/consumers/${basename}":
        ensure  => $ensure,
        content => template('eventlogging/consumer.erb'),
        notify  => Service['eventlogging/init'],
        owner   => $owner,
        group   => $group,
        mode    => $mode,
    }
}
