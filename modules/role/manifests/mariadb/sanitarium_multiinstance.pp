# sanitarium_multiinstance: it replicates from all core shards (except x1),
# and sanitizes most data on production on 7 shards, before the data
# arrives to labs
# This role installs a 10.1 version which is needed for rbr triggers for
# the new sanitarium server, which runs multi-instance and mariadb 10.1
# Eventually, this role will deprecate the original sanitarium and
# sanitarium2/sanitarium_multisource

class role::mariadb::sanitarium_multiinstance {

    system::role { 'mariadb::sanitarium':
        description => 'Sanitarium DB Server',
    }

    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::base::firewall::log

    include role::labs::db::common
    include role::labs::db::check_private_data

    include ::profile::mariadb::sanitarium_multiinstance
}
