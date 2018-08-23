# Beta Cluster DB server
#
# filtertags: labs-project-deployment-prep
class role::mariadb::beta {

    system::role { 'mariadb::beta':
        description => 'beta cluster database server',
    }

    include profile::mariadb::beta
}
