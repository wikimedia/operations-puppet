# === Class mediawiki::web::mpm_config
class mediawiki::web::mpm_config($mpm = 'prefork', $server_limit = undef, $workers_limit = undef){
    case $mpm {
        'prefork': {
            $apache_server_limit = 256
            if $workers_limit and is_integer($workers_limit) {
                $max_req_workers = min($workers_limit, $apache_server_limit)
            } else {
                # Default if no override has been defined
                $mem_available   = to_bytes($::memorytotal) * 0.7
                $mem_per_worker  = to_bytes('85M')
                $max_req_workers = min(floor($mem_available /$mem_per_worker), $apache_server_limit)
            }
            # We also need to be sure the mpm prefork module isloaded, and that worker is not.
            apache::mod_conf { 'mpm_worker':
                ensure => absent,
                before => Apache::Mod_conf['mpm_prefork']
            }
            apache::mod_conf { 'mpm_prefork':
                ensure => present,
            }

        }
        'worker': {
            # this can only be used on hhvm servers
            requires_os 'ubuntu >= trusty || debian >= jessie'

            $threads_per_child = 25
            $apache_server_limit = $::processorcount
            $max_workers = $threads_per_child * $apache_server_limit
            if $workers_limit and is_integer($workers_limit) {
                $max_req_workers = min($workers_limit, $max_workers)
            }
            else {
                # Default if no override has been defined
                $max_req_workers = $max_workers
            }
            # We also need to be sure the mpm prefork module is not loaded, and that worker is.
            apache::mod_conf { 'mpm_prefork':
                ensure => absent,
                before => Apache::Mod_conf['mpm_worker']
            }
            apache::mod_conf { 'mpm_worker':
                ensure => present,
            }
        }
        default: { fail('Only prefork and worker mpms are supported at the moment') }
    }

    apache::conf { $mpm:
        content  => template("mediawiki/apache/${mpm}.conf.erb"),
    }

}
