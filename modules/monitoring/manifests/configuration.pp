# === Class monitoring::configuration
#
# Class for common parameters for the monitoring classes and defines
#
class monitoring::configuration (
    $dir = '/etc/nagios',
    $group = "${cluster}_${::site}",
    ) {
}
Class['monitoring::configuration'] -> Monitoring::Host <| |>
Class['monitoring::configuration'] -> Monitoring::Service <| |>
Class['monitoring::configuration'] -> Monitoring::Group <| |>
