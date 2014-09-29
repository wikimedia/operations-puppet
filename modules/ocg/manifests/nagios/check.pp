# == Class ocg::nagios::check
# Sets up icinga alerts for an Offline Content Generator instance.
#
class ocg::nagios::check (
        $wjs, # warning job status queue messages i.e. 20000
        $cjs, # critical job status queue messages i.e. 30000
        $wrj, # warning render jobs queue messages i.e. 100
        $crj, # critical render jobs queue messages i.e. 500
        $url = 'http://localhost:8000/?command=health', # OCG health check URL
    ) {
    include nrpe,
        ocg::nagios::plugin

    nrpe::monitor_service { 'ocg_health':
        description  => 'OCG health',
        nrpe_command => "/usr/lib/nagios/plugins/check_ocg_health --wjs ${wjs} --cjs ${cjs} --wrj ${wrj} --crj ${crj} --url '${url}'",
    }

}
