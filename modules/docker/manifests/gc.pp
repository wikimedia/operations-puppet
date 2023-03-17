class docker::gc(
    Wmflib::Ensure            $ensure                  = 'present',
    Systemd::Timer::Interval  $interval                = '5m',
    String                    $images_high_water_mark  = '20gb',
    String                    $images_low_water_mark   = '10gb',
    String                    $volumes_high_water_mark = '20gb',
    String                    $volumes_low_water_mark  = '10gb',
){

    systemd::service { 'docker-resource-monitor':
        ensure  => $ensure,
        content => file('docker/docker-resource-monitor.service'),
        restart => true,
    }

    $command = "/usr/bin/docker run --rm \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v docker-resource-monitor:/state \
        docker-registry.wikimedia.org/docker-gc:1.0.0 \
        gc \
        --state-file /state/state.json \
        --image-filter 'id=~.*' \
        --volume-filter 'label:com.gitlab.gitlab-runner.type==cache' \
        --images ${images_high_water_mark}:${images_low_water_mark} \
        --volumes ${volumes_high_water_mark}:${volumes_low_water_mark}"

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
