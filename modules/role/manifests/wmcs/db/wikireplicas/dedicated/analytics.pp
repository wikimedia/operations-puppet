# Class role::wmcs::db::wikireplicas::dedicated::analytics
#
# This role is a special use case of role::wmcs::db::wikireplicas::analytics,
# adapted for the clouddb host used exclusively by the Analytics team.
# Some differences:
# - A different hiera config to allow to tune pt-kill configs
#   without affecting the 'regular' wikireplica hosts.
# - A different set of firewall rules for port 3306, to allow
#   Analytics hosts (especially Hadoop worker nodes) to contact
#   the wikireplica Analytics host.
#
class role::wmcs::db::wikireplicas::dedicated::analytics {

    system::role { $name:
        description => 'wikireplica database - analytics (Analytics team\'s special db host)',
    }

    include ::profile::standard
    require profile::mariadb::packages_wmf
    include profile::mariadb::wmfmariadbpy
    class { '::mariadb::service': }
    include ::profile::mariadb::monitor
    include ::profile::base::firewall

    include ::profile::wmcs::db::wikireplicas::mariadb_config
    include ::profile::wmcs::db::scriptconfig
    include ::profile::wmcs::db::wikireplicas::ferm
    include ::profile::wmcs::db::wikireplicas::monitor
    include ::profile::wmcs::db::wikireplicas::dedicated::analytics

    include ::profile::wmcs::db::wikireplicas::views
    include ::profile::mariadb::check_private_data
}
