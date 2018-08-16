# == define systemd::timer
#
# Sets up a systemd timer, but not the associated service unit, which needs to
# be declared separately before the timer.
#
# === Parameters
# [*timer_intervals*]
#   Array of Systemd::Timer::Schedule intervals at which the unit will be
#   executed. See systemd.timer(5) for details.
#
# [*splay*]
#   Sets a maximum delay to wait before starting the timer. See
#   RandomizedDelaySec in systemd.timer(5) for details.
#
# [*unit_name*]
#   The name of the unit to activate. Defaults to $title.service
#
# [*accuracy*]
#   Accuracy of the timer, in the format given by
#   Systemd::Timer::Interval. Defaults to 15 seconds, which should be good in
#   most cases.

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
        require   => Systemd::Unit[$unit_name],
    }
}
