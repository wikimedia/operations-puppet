class exim::service {
	Class["exim::config"] -> Class[exim::service]

	# The init script's status command exit value only reflects the SMTP service
	service { exim4:
		ensure => running,
		hasstatus => $exim::config::queuerunner ? {
			"queueonly" => false,
			default => true
		}
	}

	if $config::queuerunner != "queueonly" {
		# Nagios monitoring
		monitor_service { "smtp": description => "Exim SMTP", check_command => "check_smtp" }
	}
}
