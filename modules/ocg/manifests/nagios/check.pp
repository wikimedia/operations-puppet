# == Class ocg::nagios::check
# Sets up icinga alerts for an Offline Content Generator instance.
#
class ocg::nagios::check (
        $warning_temp_dir = '-', # dir size i.e. 4G
        $critical_temp_dir = '-', # dir size i.e. 5G
        $warning_output_dir = '-', # dir size i.e. 4G
        $critical_output_dir = '-', # dir size i.e. 5G
        $warning_postmortem_dir = '-', # dir size i.e. 1G
        $critical_postmortem_dir = '-', # dir size i.e. 2G
        $warning_job_status = '-', # messages i.e. 20000
        $critical_job_status = '-', # messages i.e. 30000
        $warning_render_jobs = '-', # messages i.e. 100
        $critical_render_jobs = '-', # messages i.e. 500
        $ocg_health_url = '-', # OCG URL i.e. http://localhost:8000/?command=health
    ) {
    include ocg::nagios::plugin
    $wtd = $warning_temp_dir ? {
        '-'  => '',
        default => " --wtd ${warning_temp_dir}",
    }
    $ctd = $critical_temp_dir ? {
        '-'  => '',
        default => " --ctd ${critical_temp_dir}",
    }
    $wod = $warning_output_dir ? {
        '-'  => '',
        default => " --wod ${warning_output_dir}",
    }
    $cod = $critical_output_dir ? {
        '-'  => '',
        default => " --cod ${critical_output_dir}",
    }
    $wpd = $warning_postmortem_dir ? {
        '-'  => '',
        default => " --wpd ${warning_postmortem_dir}",
    }
    $cpd = $critical_postmortem_dir ? {
        '-'  => '',
        default => " --cpd ${critical_postmortem_dir}",
    }
    $wjs = $warning_job_status ? {
        '-'  => '',
        default => " --wjs ${warning_job_status}",
    }
    $cjs = $critical_job_status ? {
        '-'  => '',
        default => " --cjs ${critical_job_status}",
    }
    $wrj = $warning_render_jobs ? {
        '-'  => '',
        default => " --wrj ${warning_render_jobs}",
    }
    $crj = $critical_render_jobs ? {
        '-'  => '',
        default => " --crj ${critical_render_jobs}",
    }
    $url = $ocg_health_report_url ? {
        '-'  => '',
        default => " --url ${ocg_health_report_url}",
    }
    monitor_service { 'ocg':
        check_command => "check_ocg_health ${wtd}${ctd}${wod}${cod}${wpd}${cpd}${wjs}${cjs}${wrj}${crj}${url}",
        description   => 'OCG health check',
    }
}
