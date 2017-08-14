define wdqs::logback_config (
    $pattern = '%d{HH:mm:ss.SSS} [%thread] %-5level %logger{36} IP:%X{IPAddress} UA:%X{UserAgent} - %msg%n',
    $logstash_host,
    $logstash_port = 11514,
) {

    file { "/etc/wdqs/logback-${title}.xml":
        ensure  => present,
        content => template('wdqs/logback.xml.erb'),
        owner   => 'root',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
    }
}
