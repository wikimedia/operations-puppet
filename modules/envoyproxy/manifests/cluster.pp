# @summary defines a file containing an envoy cluster definition
#
# @param content
#   The content of the cluster definition
#
# @param priority
#   The priority of this cluster in the clusters list
define envoyproxy::cluster(
  String $content,
  Integer[0,99] $priority = 50,
) {
  envoyproxy::conf{ $title:
    content   => $content,
    conf_type => 'cluster',
    priority  => $priority,
  }
}
