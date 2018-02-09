# == Define base::restart_service
#
# This define can be used to add an automatic restart for a stateless service:
# wmf-auto-restart checks whether any dependant library has been refreshed and
# if that's the case, a restart is triggered. The restarts are spread out over
# the course of the day via fqdn_rand()
#
define base::service_auto_restart(
    $service_name,
    $ensure  = present,
) {
    @cron { "wmf_auto_restart_${service_name}":
        ensure  => $ensure,
        command => "/usr/local/sbin/wmf-auto-restart -s ${service_name}",
        user    => 'root',
        hour    => fqdn_rand(23, "${service_name}_auto_restart"),
        minute  => fqdn_rand(59, "${service_name}_auto_restart"),
        weekday => '1-5',
        require => File['/usr/local/sbin/wmf-auto-restart'],
    }
}
