# == Define: logstash::output::sentry
#
# Configure logstash to output to Sentry.
#
# You can find the required parameters in the Sentry DSN, which looks like
# http(s)://<key>:<secret>@<host>/<project_id>
#
# == Parameters:
# - $ensure: Whether the config should exist. Default present.
# - $host: Sentry server.
# - $key: Sentry key.
# - $secret: Sentry secret.
# - $project_id: Sentry project ID.
# - $use_ssl: Whether to use HTTPS (defaults to true).
# - $msg: Sentry event title (defaults to "Message from logstash").
# - $level_tag: Sentry severity level (defaults to 'error').
# - $fields_to_tags: Whether to set logstash fields as extra fields
#   in Sentry (defaults to true).
#
# == Sample usage:
#
#   logstash::output::sentry { 'sentry':
#       host       => 'sentry-beta.wmflabs.org',
#       key        => 'd047f51cfe7f413398762d25093936bc',
#       secret     => '0f39f34792d04ef6b8da025f07a3bac1'
#       project_id => '2',
#   }
#
define logstash::output::sentry(
    $ensure         = present,
    $host,
    $key,
    $secret,
    $project_id,
    $use_ssl        = true,
    $msg            = undef,
    $level_tag      = undef,
    $fields_to_tags = true,
) {
    logstash::conf { "output-sentry-${title}":
        ensure   => $ensure,
        content  => template('logstash/output/sentry.erb'),
        priority => $priority,
    }
}
# vim:sw=4 ts=4 sts=4 et:
