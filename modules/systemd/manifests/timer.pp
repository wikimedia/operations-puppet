# == define systemd::timer
# Sets up a systemd timer, but not the associated service unit

define systemd::timer(
    Array[Systemd::Timer::Schedule, 1] $timer_intervals,
    String $unit_name="${title}.service",
    Wmflib::Ensure $ensure = 'present',
    Integer $splay = 0,
    Systemd::Timer::Interval $accuracy = '15sec',
) {
    # Timer service
    systemd::service { $title:
        ensure    => $ensure,
        unit_type => 'timer',
        content   => template('systemd/systemd.timer.erb'),
        require   => Systemd::Service[$unit_name],
    }
}
