# == Define: cassandra::reporter::topk
#
# Sets up the topk Cassandra reporter, which reports the topk partitions
# measured by size for the Cassandra cluster given as the title of the define.
#
# === Parameters
#
# [*title*]
#   Required. The name of the Cassandra cluster for which to report.
#
# [*email*]
#   Required. The e-mail address to send the report to.
#
# [*no_results*]
#   The number of results to display on the report. Default: 50
#
# [*no_days*]
#   The interval, in days, between two reports. Apart from a number, one can
#   also use the special aliases 'daily' (every day) and 'weekly' (every
#   Sunday). The reports are always generated at 23:50. If you just want to
#   install the script that generates the report (without setting up cron), set
#   this parameter to 0 or undef. Default: 'weekly'
#
define cassandra::reporter::topk(
    $email,
    $no_results = 50,
    $no_days    = 'weekly',
) {

    # install the script
    require ::cassandra::reporter::topk::bin

    $bin = $::cassandra::reporter::topk::bin::fpath

    # figure out the cron job time definition
    if $no_days == 'daily' {
        $cron_time = '50 23 * * *'
        $last_days = 1
    } elsif $no_days == 'weekly' {
        $cron_time = '50 23 * * 0'
        $last_days = 7
    } elsif !defined($no_days) or $no_days == 0 {
        $cron_time = ''
    } else {
        $cron_time = "50 23 */${no_days} * *"
        $last_days = $no_days
    }

    # set up the cron job only if a time definition has been set
    unless $cron_time == '' {
        # load the configuration and ensure the log dir exists
        require ::cassandra::reporter
        $logstash_es_host = $::cassandra::reporter::logstash_es_host
        $logstash_es_port = $::cassandra::reporter::logstash_es_port
        $log_file = "${::cassandra::reporter::log_dir}/${title}.topk"
        # make sure the log files are readable
        file { "${log_file}.out":
            ensure  => present,
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            replace => false,
        }
        file { "${log_file}.err":
            ensure  => present,
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            replace => false,
        }
        # install the cron job
        base::crond { "cassandra-reporter-topk-${title}":
            command  => template('cassandra/reporter/topk.cron.erb'),
            time     => $cron_time,
            redirect => ["${log_file}.out", "${log_file}.err"],
            require  => File["${log_file}.out", "${log_file}.err"],
        }
    }

}
