class docker::gc(
    Wmflib::Ensure            $ensure                  = 'present',
    String                    $image_filter            = 'id=~.*',
    String                    $volume_filter           = 'id=~.*',
    Boolean                   $use_creation_dates      = false,
    Systemd::Timer::Interval  $interval                = '5m',
    Integer                   $timeout                 = 60,
    String                    $images_high_water_mark  = '20gb',
    String                    $images_low_water_mark   = '10gb',
    String                    $volumes_high_water_mark = '20gb',
    String                    $volumes_low_water_mark  = '10gb',
){
    $gc_version      = '1.3.0'
    $image_repo_path = 'docker-registry.wikimedia.org/repos/releng/docker-gc'
    $ensure_monitor = $use_creation_dates ? {
        true    => absent,
        default => present,
    }

    systemd::service { 'docker-resource-monitor':
        ensure  => $ensure_monitor,
        content => template('docker/docker-resource-monitor.service.erb'),
        restart => true,
    }

    $common_docker_opts = "/usr/bin/docker run --rm \
        --user root \
        -v /var/run/docker.sock:/var/run/docker.sock"
    $common_gc_opts = "${$image_repo_path}/docker-gc:${gc_version} \
        --timeout ${timeout} \
        --image-filter '${image_filter}' \
        --volume-filter '${volume_filter}' \
        --images ${images_high_water_mark}:${images_low_water_mark} \
        --volumes ${volumes_high_water_mark}:${volumes_low_water_mark}"

    if $use_creation_dates {
        $command = "${common_docker_opts} \
        ${common_gc_opts} \
        --use-creation-dates"
    } else {
        $command = "${common_docker_opts} \
        -v docker-resource-monitor:/state \
        ${common_gc_opts} \
        --state-file /state/state.json"
    }

    systemd::timer::job { 'docker-gc':
        ensure      => $ensure,
        description => 'Perform a round of docker image/volume garbage collection',
        command     => $command,
        user        => 'root',
        interval    => {
            'start'    => 'OnUnitInactiveSec',
            'interval' => $interval,
        },
    }
}
