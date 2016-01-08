# == Define: logstash::output::sentry
#
# Configure logstash to output to Sentry.
#
# == Parameters:
# - $dsn: Sentry DSN.
# - $msg: Sentry event title (defaults to "Message from logstash").
# - $level_tag: Sentry severity level (defaults to 'error').
# - $fields_to_tags: Whether to set logstash fields as extra fields
#   in Sentry (defaults to true).
# - $ensure: Whether the config should exist. Default present.
#
# == Sample usage:
#
#   logstash::output::sentry { 'sentry':
#       dsn => 'https://d047f51cfe7f413398762d25093936bc:0f39f34792d04ef6b8da025f07a3bac1@sentry-beta.wmflabs.org/2',
#   }
#
define logstash::output::sentry(
    $dsn,
    $msg            = undef,
    $level_tag      = undef,
    $fields_to_tags = true,
    $ensure         = present,
) {
    logstash::conf { "output-sentry-${title}":
        ensure   => $ensure,
        content  => template('logstash/output/sentry.erb'),
        priority => $priority,
    }
}
# vim:sw=4 ts=4 sts=4 et:
