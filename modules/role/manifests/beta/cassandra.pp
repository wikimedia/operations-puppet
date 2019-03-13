# == Class role::beta::cassandra
#
# Ad-hoc Cassandra clusters for deployment-prep.
# filtertags: labs-project-deployment-prep
class role::beta::cassandra {
    system::role { 'Basic Cassandra cluster': }
    include ::standard
    include ::profile::cassandra
}
