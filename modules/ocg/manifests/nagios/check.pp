# == Class ocg::nagios::check
# Sets up icinga alerts for an Offline Content Generator instance.
#
class ocg::nagios::check (
        $wtd, # warning temp dir size i.e. 4G
        $ctd, # critical temp dir size i.e. 5G
        $wod, # warning output dir size i.e. 4G
        $cod, # critical output dir size i.e. 5G
        $wpd, # warning postmortem dir size i.e. 1G
        $cpd, # critical postmortem dir size i.e. 2G
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
        nrpe_command => "/usr/lib/nagios/plugins/check_ocg_health --wtd ${wtd} --ctd ${ctd} --wod ${wod} --cod ${cod} --wpd ${wpd} --cpd ${cpd} --wjs ${wjs} --cjs ${cjs} --wrj ${wrj} --crj ${crj} --url '${url}'",
    }

}
