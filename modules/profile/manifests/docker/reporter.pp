# SPDX-License-Identifier: Apache-2.0
# @summary This profile installs docker-report, and runs the report with the required frequency.
# @param proxy the http procy to use if any
# @param generate_reports if we should generate reports
class profile::docker::reporter(
    Boolean                   $generate_reports = lookup('profile::docker::reporter::generate_reports'),
    Optional[Stdlib::HTTPUrl] $proxy            = lookup('http_proxy'),
) {
    ensure_packages(['python3-docker-report'])
    $report_ensure = $generate_reports.bool2str('present', 'absent')

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
            ensure    => absent,
            frequency => 'weekly',
            ;
        # Report on images used in production on k8s
        'k8s':
            frequency => 'weekly',
            ;
    }
}
