# == Define: prometheus::mysqld_exporter::instance
#
# Prometheus exporter for MySQL server metrics. The exporter is most effective
# when ran alongside the MySQL server to be monitored, connecting via a local
# UNIX socket is supported.
#
# = Parameters
#
# [*client_socket*]
#   The socket to connect to.
#
# [*client_user*]
#   MySQL user
#
# [*client_password*]
#   MySQL password
#
# [*listen_address*]
#   ip/host and port, colon separated, where the prometheus exporter will listen for
#   http metrics requests. Host can be omitted.
#
# [*arguments*]
#   Additional command line arguments for prometheus-mysqld-exporter.

define prometheus::mysqld_exporter::instance (
    $client_socket = '/run/mysqld/mysqld.sock',
    $client_user = 'prometheus',
    $client_password = 'This is a fake passsword, but cannot be empty due to Debian #953040',
    $listen_address = ':9104',
    $arguments = '',
) {
    include prometheus::mysqld_exporter::common

    $my_cnf = "/var/lib/prometheus/.my.${title}.cnf"
    $service = "prometheus-mysqld-exporter@${title}"

    # prometheus collector option formatting changed since buster
    if debian::codename::ge('buster') {
        $option_string = '--'
    } else {
        $option_string = '-'
    }
    $instance_options = "${option_string}web.listen-address \"${listen_address}\" \
${option_string}config.my-cnf \"${my_cnf}\""

    # Add sane default arguments if none provided
    if $arguments == '' {
        $common_options = "${option_string}collect.global_status \
${option_string}collect.global_variables \
${option_string}collect.info_schema.processlist \
${option_string}collect.slave_status"
        if debian::codename::ge('buster') {
            $general_options = "${common_options} ${option_string}no-collect.info_schema.tables"
        } else {
            $general_options = "${common_options} ${option_string}collect.info_schema.processlist.min_time 0 \
${option_string}collect.info_schema.tables false"
        }
    } else {
        $general_options = $arguments
    }

    file { "/etc/default/prometheus-mysqld-exporter@${title}":
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => "ARGS='${instance_options} ${general_options}'",
        notify  => Service[$service],
    }

    # a separate database config (.my.<instance_name>cnf) for each instance monitored
    # change the systemd unit if the patch changes here, as it depends on it
    file { $my_cnf:
        ensure  => present,
        mode    => '0400',
        owner   => 'prometheus',
        group   => 'prometheus',
        content => template('prometheus/mysqld_exporter.cnf.erb'),
        notify  => Service[$service],
    }

    service { $service:
        ensure  => running,
        require => File['/lib/systemd/system/prometheus-mysqld-exporter@.service'],
    }

    base::service_auto_restart { $service: }
}
