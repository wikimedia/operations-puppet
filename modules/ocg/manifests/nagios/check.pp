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
    include ocg::nagios::plugin
    monitor_service { 'ocg':
        check_command => "check_ocg_health!${wtd}!${ctd}!${wod}!${cod}!${wpd}!${cpd}!${wjs}!${cjs}!${wrj}!${crj}!${url}",
        description   => 'OCG health check',
    }
}
