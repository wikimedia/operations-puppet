
class udpprofile::collector {
  system_role { "udpprofile::collector": description => "MediaWiki UDP profile collector" }

  package { "udpprofile":
    ensure => latest;
  }

  service { udpprofile:
    require => Package[ 'udpprofile' ],
    enable => true,
    ensure => running;
  }

  # Nagios monitoring (RT-2367)
  monitor_service { "carbon-cache": description => "carbon-cache.py", check_command => "nrpe_check_carbon_cache" }
  monitor_service { "profiler-to-carbon": description => "profiler-to-carbon", check_command => "nrpe_check_profiler_to_carbon" }
  monitor_service { "profiling collector": description => "profiling collector", check_command => "nrpe_check_profiling_collector" }

}
