# == Class ocg::nagios
# Sets up icinga alerts for an Offline Content Generator instance.
#
class ocg::nagios (
    $wjs = 800000, # warning job status queue messages i.e. 20000
    $cjs = 1500000 , # critical job status queue messages i.e. 30000
    $wrj = 500, # warning render jobs queue messages i.e. 100
    $crj = 3000, # critical render jobs queue messages i.e. 500
    $url = 'http://localhost:8000/?command=health', # OCG health check URL
) {

    include nrpe

    file { '/usr/lib/nagios/plugins/check_ocg_health':
        source  => 'puppet:///modules/ocg/nagios/check_ocg_health',
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        require => Package['nagios-plugins'],
    }

    nrpe::monitor_service { 'ocg_health':
        description  => 'OCG health',
        nrpe_command => "/usr/lib/nagios/plugins/check_ocg_health --wjs ${wjs} --cjs ${cjs} --wrj ${wrj} --crj ${crj} --url '${url}'",
    }
}
