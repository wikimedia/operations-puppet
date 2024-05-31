# sanitarium_multiinstance: it replicates from all core shards (except x1),
# and sanitizes most data on production on 7 shards, before the data
# arrives to labs
# This role installs a 10.1 version which is needed for rbr triggers for
# the new sanitarium server, which runs multi-instance and mariadb 10.1
# Eventually, this role will deprecate the original sanitarium and
# sanitarium2/sanitarium_multisource

class role::mariadb::sanitarium_multiinstance {
    include profile::base::production
    include profile::firewall

    include profile::wmcs::db::scriptconfig
    include profile::mariadb::check_private_data

    include profile::mariadb::sanitarium_multiinstance
}
