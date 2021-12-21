# This profile installs docker-report, and runs the report with the required frequency.
class profile::docker::reporter(
    String $proxy = lookup('http_proxy'),
    Boolean $generate_reports = lookup('profile::docker::reporter::generate_reports'),
) {
    package { 'python3-docker-report':
        ensure => present,
    }
    $report_ensure = $generate_reports ? {
        true => 'present',
        default => 'absent',
    }
    profile::docker::reporter::report {
        default:
            ensure => $report_ensure,
            proxy  => $proxy,
            ;
        # Report on base images and production-images
        'base':
            frequency => 'daily',
            ;
        # Report on releng images
        'releng':
            frequency => 'weekly',
            ;
        # Report on images used in production on k8s
        'k8s':
            frequency => 'weekly',
            ;
    }
}
