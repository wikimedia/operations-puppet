# = Class: toollabs::services
# Provides various services based off tools manifests
class toollabs::services {
    package { 'tools-manifest':
        ensure => latest,
    }

    service { 'webservicemonitor':
        ensure    => running,
        subscribe => Package['tools-manifest'],
    }
}
