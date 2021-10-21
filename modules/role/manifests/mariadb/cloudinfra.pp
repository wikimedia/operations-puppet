# This role is to be used for the `cloudinfra` labs project instances.
# This is going to hold the labspuppet database previously housed on the
# production m5 shard, and may hold others in future.
class role::mariadb::cloudinfra (
    Boolean $master = false,
) {
    system::role { 'mariadb::misc':
        description => 'Cloudinfra database',
    }

    $mysql_role = $master ? {
        true  => 'master',
        false => 'slave',
    }

    include ::profile::base::production
    include ::profile::mariadb::monitor
    include ::profile::base::firewall

    include ::profile::mariadb::monitor::prometheus

    include ::profile::mariadb::grants::cloudinfra
    class { '::profile::mariadb::cloudinfra':
        master => $master,
    }
}
