# = Define: logstash::input::dlq
#
# Configure logstash to collect input from the dead letter queue.
#
# == Parameters:
# - $ensure: Whether the config should exist.  Default: present
# - $path: base path of the dead letter queue (logstash.yml:path.dead_letter_queue).  Default: /var/lib/logstash/dead_letter_queue
# - $pipeline_id: ID of the pipeline whose events you want to read from. Default: $title.
# - $commit_offsets: Should Logstash mark events as consumed. Default: true.
# - $priority: Configuration loading priority. Default: 10.
# - $plugin_id: Name associated with Logstash metrics.  Default: input/dlq
# - $tags: Array of tags to be added to the logs.  Default: undef
#
# == Sample usage:
#
#   logstash::input::dlq { 'main': }
#
define logstash::input::dlq(
    Wmflib::Ensure   $ensure         = present,
    Stdlib::Unixpath $path           = '/var/lib/logstash/dead_letter_queue',
    String           $pipeline_id    = $title,
    Boolean          $commit_offsets = true,
    Integer          $priority       = 10,
    String           $plugin_id      = 'input/dlq',
    Optional[Array]  $tags           = ['dlq'],
) {
    logstash::conf { "input-dlq-${title}":
        ensure   => $ensure,
        content  => template('logstash/input/dlq.erb'),
        priority => $priority,
    }
}
