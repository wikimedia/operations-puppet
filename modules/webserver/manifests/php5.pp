# === Class webserver::php5
#
# Install a basic apache2 web server with mod_php
#
class webserver::php5(
    $ssl = 'false',
    ) {

    include webserver::sysctl_settings
    include ::apache
    include ::apache::mod::php5

    if $ssl == true {
        include ::apache::mod::ssl
    }

    # Monitoring
    monitor_service { 'http':
        description   => 'HTTP',
        check_command => 'check_http',
    }
}
