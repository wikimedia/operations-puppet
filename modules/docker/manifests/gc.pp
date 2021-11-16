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

    # To start, I'm not including a volumes filter, so no volumes will
    # be deleted.  Need to see what volume names and/or labels are
    # created by Gitlab runners first.
    $command = "/usr/bin/docker run --rm \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v docker-resource-monitor:/state \
        docker-registry.wikimedia.org/docker-gc:1.0.0 \
        gc \
        --state-file /state/state.json \
        --image-filter 'id=~.*' \
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
