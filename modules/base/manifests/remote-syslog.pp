class base::remote-syslog {
    if ($::hostname != 'lithium') and ($::instancename != 'deployment-bastion') {

        $syslog_host = $::realm ? {
            'production' => 'syslog.eqiad.wmnet',
            'labs'       => "deployment-bastion.${::site}.wmflabs",
        }

        rsyslog::conf { 'remote_syslog':
            content  => "*.info;mail.none;authpriv.none;cron.none @${syslog_host}",
            priority => 30,
        }
    }
}