define wdqs::logback_config (
    $logstash_host,
    $logstash_port = 11514,
    $pattern = '%d{HH:mm:ss.SSS} [%thread] %-5level %logger{36} IP:%X{req.remoteHost} UA:%X{req.userAgent} - %msg%n',
) {

    file { "/etc/wdqs/logback-${title}.xml":
        ensure  => present,
        content => template('wdqs/logback.xml.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
    }
}
