# filtertags: labs-project-deployment-prep
class role::mediawiki::videoscaler {
    system::role { 'role::mediawiki::videoscaler': }

    # Parent role
    include ::role::mediawiki::scaler

    # Runners configuration for videoscalers

    # TODO: restructure the jobrunner profile to get percentages of total runners
    # and the total number of runners, to make this a bit more sane, and uniform across
    # usage

    # We have multiple long-running processes occupying as much as 2 cores
    $total_runners = floor(0.7 * $facts['processorcount'])
    # We need some hhvm threads to be free to account for monitoring
    # requests
    $hhvm_threads = $total_runners + 5
    # Have at max 8 runners for normal jobs
    $runners = min(ceiling(0.5 * $total_runners), 8)
    # Leave the rest to prioritized jobs
    $prioritized_runners = $total_runners - $runners
    # Profiles
    include ::role::prometheus::apache_exporter
    include ::role::prometheus::hhvm_exporter
    include ::profile::mediawiki::jobrunner
    include ::base::firewall

    # Change the apache2.conf Timeout setting
    augeas { 'apache timeout':
        incl    => '/etc/apache2/apache2.conf',
        lens    => 'Httpd.lns',
        changes => [
            'set /files/etc/apache2/apache2.conf/directive[self::directive="Timeout"]/arg 86400',
        ],
        notify  => Service['apache2'],
    }
}
