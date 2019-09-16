define query_service::logback_config (
    String $pattern,
    String $deploy_name,
    Stdlib::Unixpath $log_dir,
    Stdlib::Port $logstash_logback_port = 11514,
    Boolean $evaluators = false,
    Boolean $sparql = false,
) {
    file { "/etc/${deploy_name}/logback-${title}.xml":
        ensure  => present,
        content => template('query_service/logback.xml.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
    }
}
