# == Define kafkatee::input
# Configures a kafkatee input.  This can be either from Kafka
# or from a subprocess pipe.  If from Kafka, the brokers consumed from
# are global for this kafkatee instance and configured using
# the main kafkatee class.
#
# == Parameters
# $type             - Type of kafkatee input.  Either 'pipe' or 'kafka'.
#                     Default: kafka
# $topic            - Kafka topic from which to consume.  Default: undef
# $partitions       - Kafka topic partitions from which to consume.
#                     This can be a list of partitions, or a range, e.g. 0-9.
#                     Default undef.
# $offset           - Offset type from which to consume in Kafka.
#                     One of: beginning, end, stored, or a hardcoded offset integer.
#                     Default: end
# $options          - Hash of key => value options to pass to this input.
#                     Default: {}
# $command          - If $type is pipe, then this command will be launched and its
#                     stdout will be used as input data.
#
define kafkatee::input(
    $type           = 'kafka',
    $topic          = undef,
    $partitions     = undef,
    $offset         = 'end',
    $options        = {},
    $command        = undef,
    $ensure         = 'present',
)
{
    file { "/etc/kafkatee.d/input.${title}.conf":
        ensure  => $ensure,
        content => template("kafkatee/input.${type}.conf.erb"),
        notify  => Service['kafkatee'],
    }
}
