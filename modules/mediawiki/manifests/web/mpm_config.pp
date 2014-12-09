# === Class mediawiki::web::mpm_config
class mediawiki::web::mpm_config($worker = 'prefork', $server_limit = undef, $workers_limit = undef){
    case $worker {
        'prefork': {
            $apache_server_limit = 256
            if is_integer($workers_limit) {
                $max_req_workers = min($workers_limit, $apache_server_limit)
            } else {
                $mem_available   = to_bytes($::memorytotal) * 0.7
                $mem_per_worker  = to_bytes('85M')
                $max_req_workers = min(floor($mem_available /$mem_per_worker), $apache_server_limit)
            }
        }
        'worker': {
            # this can only be used on hhvm servers
            requires_os 'ubuntu >= trusty || debian >= jessie'

            $threads_per_child = 25
            $apache_server_limit = $::processorcount
            $max_workers = $threads_per_child * $apache_server_limit
            if is_integer($workers_limit) {
                $max_req_workers = min($workers_limit, $max_workers)
            }
            else {
                $max_req_workers = $max_workers
            }
        }
        default: { fail('Only prefork and worker mpms are supported at the moment') }
    }

    apache::conf { $worker:
        content  => template("mediawiki/apache/${worker}.conf.erb"),
    }

}
