# == Define: logstash::output::opensearch
#
# Configure logstash to output to OpenSearch
#
# == Parameters:
# - $ensure: Whether the config should exist. Default present.
# - $scheme: Scheme of the hosts uri (http/https).  Not populated if undef.
# - $host: OpenSearch server. Default '127.0.0.1'.
# - $username: Username to use for http basic auth.
# - $password: Password to use for http basic auth.
# - $cacert: Path to the ca certificate to authenticate the endpoint, e.g. /etc/certs/ca.pem
# - $index: Index to write events to. Default '${title}-%{+YYYY.MM.dd}'.
# - $port: OpenSearch server port. Default 9200.
# - $guard_condition: Logstash condition to require to pass events to output.
#       Default undef.
# - $priority: Configuration loading priority. Default 90.
# - $template: Path to OpenSearch mapping template. Default undef.
# - $template_name: Name of OpenSearch mapping template.
#       Default $title.
# - $document_type: Set the OpenSearch document type to write events to. Default undef.
# - $plugin_id: Name associated with Logstash metrics
#
# == Sample usage:
#
#   logstash::output::opensearch { 'logstash':
#       host            => '127.0.0.1',
#       guard_condition => '"es" in [tags]',
#       manage_indices  => true,
#   }
#
define logstash::output::opensearch (
    Wmflib::Ensure                             $ensure           = present,
    Optional[Enum['http', 'https']]            $scheme           = undef,
    Variant[Stdlib::IP::Address, Stdlib::Fqdn] $host             = '127.0.0.1',
    Optional[String]                           $username         = undef,
    Optional[Sensitive[String]]                $password         = undef,
    Optional[Stdlib::Unixpath]                 $cacert           = undef,
    String                                     $index            = "${title}-%{+YYYY.MM.dd}",
    Integer                                    $port             = 9200,
    Optional[String]                           $guard_condition  = undef,
    Integer                                    $priority         = 90,
    Optional[String]                           $template         = undef,
    String                                     $template_name    = $title,
    Optional[String]                           $document_type    = undef,
    String                                     $plugin_id        = "output/opensearch/${title}",
) {
    logstash::conf{ "output-opensearch-${title}":
        ensure   => $ensure,
        content  => template('logstash/output/opensearch.erb'),
        priority => $priority,
    }
}
# vim:sw=4 ts=4 sts=4 et:
