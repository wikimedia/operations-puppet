# Class role::labs::db::wikireplica_analytics::dedicated
#
# This role is a special use case of role::labs::db::wikireplica_analytics,
# adapted for the labsdb host used exclusively by the Analytics team.
# Some differences:
# - A different hiera config to allow to tune pt-kill configs
#   without affecting the 'regular' labsdb hosts.
# - A different set of firewall rules for port 3306, to allow
#   Analytics hosts (especially Hadoop worker nodes) to contact
#   the labsdb Analytics host.
#
class role::labs::db::wikireplica_analytics::dedicated {

    system::role { 'labs::db::wikireplica_analytics::dedicated':
        description => 'Labs replica database - analytics (Analytics team\'s special db host)',
    }

    include ::profile::standard
    class { '::mariadb::packages_wmf': }
    class { '::mariadb::service': }
    include ::profile::mariadb::monitor
    include ::profile::base::firewall

    include ::profile::labs::db::wikireplica
    include ::profile::labs::db::wikireplica::analytics

    include ::passwords::misc::scripts
    include ::role::labs::db::common
    include ::profile::labs::db::views
    include ::role::labs::db::check_private_data
    include ::profile::labs::db::kill_long_running_queries

}
