# Profile class for adding backup functionalities to a host
#
# Note that the hiera key lookups have a name space of profile::backup instead
# of profile::backup::host. That's cause they are reused in other profile
# classes in the same hierarchy and is consistent with our code guidelines
#
# This profile class also does a small hack. It relies on
# profile::backup::enable being set to true before actually doing anything.
# That's because we can not provide meaningful default values for any of the
# other hiera calls, but still want to use the profile class in environments
# where backup is not set up. In that case we shortcircuit the class to be
# effectively a noop
class profile::backup::host(
    $enable = hiera('profile::backup::enable', false)
){
    if $enable {
        $pool     = hiera('profile::backup::pool')
        $director = hiera('profile::backup::director')
        $days     = hiera('profile::backup::days')
        class { 'bacula::client':
            director       => $director,
            catalog        => 'production',
            file_retention => '60 days',
            job_retention  => '60 days',
        }

        # This will use uniqueid fact to distribute (hopefully evenly) machines on
        # days of the week
        $day = inline_template('<%= @days[[@uniqueid].pack("H*").unpack("L")[0] % 7] -%>')

        $jobdefaults = "Monthly-1st-${day}-${pool}"

        # Realize the various virtual resources that may have been defined
        Bacula::Client::Job <| |> {
            require => Class['bacula::client'],
        }
        File <| tag == 'backup-motd' |>

        # If the machine includes ::base::firewall then let director connect to us
        # TODO The IPv6 IP should be converted into a DNS AAAA resolve once we
        # enabled the DNS record on the director
        ferm::service { 'bacula-file-demon':
            proto  => 'tcp',
            port   => '9102',
            srange => "(@resolve(${director}) 2620:0:861:101:10:64:0:179)",
        }
    }
}

