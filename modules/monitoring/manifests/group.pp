# == Define monitoring::group
# Define host groups and service groups in the monitoring system.
# Note that these will be applied by naginator and are the only
# resource we don't manage via naggen2.
#
# == Parameters
# [*description*]
# Plain-text description of the group.
#
# [*config_dir*]
# Nagios config dir, by default '/etc/nagios'
#
define monitoring::group (
    $description,
    $ensure=present,
    $config_dir = '/etc/nagios'
    ) {

    # Nagios hostgroup instance
    nagios_hostgroup { $title:
        ensure         => $ensure,
        target         => "${config_dir}/puppet_hostgroups.cfg",
        hostgroup_name => $title,
        mode           => '0444',
        alias          => $description,
    }

    # Nagios servicegroup instance
    nagios_servicegroup { $title:
        ensure            => $ensure,
        target            => "${config_dir}/puppet_servicegroups.cfg",
        servicegroup_name => $title,
        mode              => '0444',
        alias             => $description,
    }

}
