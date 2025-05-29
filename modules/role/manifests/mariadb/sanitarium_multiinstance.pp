# sanitarium_multiinstance: it replicates from all core shards (except x1),
# and sanitizes most data on production on 8 shards, before the data
# arrives to labs
# This role uses rbr triggers and runs multi-instance.

class role::mariadb::sanitarium_multiinstance {
    include profile::base::production
    include profile::firewall

    include profile::wmcs::db::scriptconfig
    include profile::mariadb::check_private_data

    include profile::mariadb::sanitarium_multiinstance
}
