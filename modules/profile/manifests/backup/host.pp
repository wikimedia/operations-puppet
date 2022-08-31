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
    Boolean             $enable         = lookup('profile::backup::enable'),
    String              $pool           = lookup('profile::backup::pool'),
    Stdlib::Host        $director       = lookup('profile::backup::director'),
    Array[String]       $days           = lookup('profile::backup::days'),
    String              $director_seed  = lookup('profile::backup::director_seed'),
){

    if $enable {
        class { 'bacula::client':
            director         => $director,
            catalog          => 'production',
            file_retention   => '90 days',
            job_retention    => '90 days',
            directorpassword => fqdn_rand_string(32, '', $director_seed)
        }

        # This will use uniqueid fact to distribute (hopefully evenly) machines on
        # days of the week
        $day = inline_template('<%= @days[[@uniqueid].pack("H*").unpack("L")[0] % 7] -%>')

        $jobdefaults = "Monthly-1st-${day}-${pool}"

        # Realize the various virtual resources that may have been defined
        Bacula::Client::Job <| |> {
            require => Class['bacula::client'],
        }
        Motd::Script <| tag == 'backup-motd' |>

        # If the machine includes ::profile::base::firewall then let director connect to us
        ferm::service { "bacula-file-daemon-${director}":
            proto  => 'tcp',
            port   => '9102',
            srange => "(@resolve(${director}) @resolve(${director}, AAAA))",
        }
    }
}
