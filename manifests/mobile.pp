# This file is for mobile classes

class mobile::vumi {
	package { "python-iso8601":
		ensure => "0.1.4-0"
	}

	package { "python-redis":
		ensure => "2.4.5-1"
	}

	package { "python-smpp":
		ensure => "0.1-0"
	}

	package { "python-ssmi":
		ensure => "0.0.4-0"
	}

        package { "redis-server":
                ensure => "latest"
        }

        package { "python-txamqp":
                ensure => "0.6.1-0"
        }

        package { "vumi":
                ensure => "0.4.0~a+git2012040612-0"
        }

        package { "vumi-wikipedia":
                ensure => "0.1~a+git2012040614-0"
        }

        package { "python-twisted":
                ensure => "latest"
        }

        package { "python-tz":
                ensure => "latest"
        }

        package { "python-wokkel":
                ensure => "0.6.3-1"
        }

        package { "rabbitmq-server":
                ensure => "latest"
        }
}
