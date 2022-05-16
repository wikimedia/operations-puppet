# Configure backing up all of /srv on the cluster management hosts
# so data for infrastructure deplotments and pwstore are not lost
class profile::cluster::management::backup () {
    backup::set { 'srv-deployment': }  # this backs up all of /srv
    backup::set { 'home': }
    backup::set { 'cluster-management-logs': }
}
