# == Class: restbase::cassandra_report
#
# Sets up the host to be a reporter for RESTBase's Cassandra. So far, it only
# sets up the topk-partition reporter.
#
class restbase::cassandra_report(
) {

    # set up the topk reporter weekly, sending the report by email to
    # services@wikimedia.org
    cassandra::reporter::topk { 'eqiad':
        email => 'services@wikimedia.org',
    }
}
