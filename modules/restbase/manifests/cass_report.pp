# == Class: restbase::cass_report
#
# Sets up the host to be a reporter for RESTBase's Cassandra. So far, it only
# sets up the topk-partition reporter.
#
# === Parameters
#
# [*cluster_name*]
#   The logical name of RESTBase's Cassandra cluster. Default: 'eqiad'
#
class restbase::cass_report(
    $cluster_name = 'eqiad',
) {

    # set up the topk reporter weekly, sending the report by email to
    # services@wikimedia.org
    cassandra::reporter::topk { $cluster_name: }
}
