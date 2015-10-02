define tlsproxy::ocsp_stapler($certs) {
    require tlsproxy::ocsp_updater

    $proxy  = "webproxy.${::site}.wmnet:8080"
    $output = "/var/cache/ocsp/${name}.ocsp"
    $config = "/etc/update-ocsp.d/${title}.conf"

    exec { "${title}-create-ocsp":
        command => "/usr/local/sbin/update-ocsp --config ${config}",
        creates => $output,
        require => File[$config],
    }

    file { $config:
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('tlsproxy/update-ocsp.erb'),
        require => Sslcert::Certificate[$certs],
    }
}
