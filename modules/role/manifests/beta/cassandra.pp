# == Class role::beta::cassandra
#
# Ad-hoc Cassandra clusters for deployment-prep.
class role::beta::cassandra {
    include profile::base::production
    include profile::cassandra
}
