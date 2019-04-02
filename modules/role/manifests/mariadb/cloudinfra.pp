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

    include ::standard
    include ::profile::mariadb::monitor
    include ::profile::base::firewall

    class { 'profile::mariadb::monitor::prometheus':
        mysql_group => 'misc',
        mysql_role  => $mysql_role,
    }

    include ::profile::mariadb::grants::cloudinfra
    class { '::profile::mariadb::cloudinfra':
        master => $master,
    }
}
