define wdqs::logback_config (
    String $pattern,
    String $logstash_host,
    Wmflib::IpPort $logstash_port = 11514,
    Boolean $evaluators = false,
) {
    file { "/etc/wdqs/logback-${title}.xml":
        ensure  => present,
        content => template('wdqs/logback.xml.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
    }
}
