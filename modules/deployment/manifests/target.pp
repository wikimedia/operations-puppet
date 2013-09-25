define deployment::target($ensure=present) {
    salt::grain { "deployment_target_${name}":
        ensure => $ensure,
        grain  => "deployment_target",
        value  => $name,
        notify => [
            Exec["deployment_target_sync_all"],
            Exec["deployment_target_refresh_pillars"],
        ];
    }
    if ! defined(Exec["deployment_target_sync_all"]){
        exec { "deployment_target_sync_all":
            refreshonly => true,
            path        => ["/usr/bin"],
            command     => "salt-call saltutil.sync_all";
        }
    }
    if ! defined(Exec["deployment_target_refresh_pillars"]){
        exec { "deployment_target_refresh_pillars":
            refreshonly => true,
            path        => ["/usr/bin"],
            command     => "salt-call saltutil.refresh_pillar";
        }
    }
    include deployment::packages
}
