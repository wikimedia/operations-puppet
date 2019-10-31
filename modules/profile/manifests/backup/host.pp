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
    Array[Stdlib::Host] $ferm_directors = lookup('profile::backup::ferm_directors'),
    String              $pool           = lookup('profile::backup::pool'),
    Stdlib::Host        $director       = lookup('profile::backup::director'),
    Array[String]       $days           = lookup('profile::backup::days'),
){


    # TODO: $ferm_directors is temporary to help with the migration, we should
    # fall back to $director and remove this hiera call when done
    if $enable {
        class { 'bacula::client':
            director       => $director,
            catalog        => 'production',
            file_retention => '30 days',
            job_retention  => '30 days',
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

        # If the machine includes ::profile::base::firewall then let director connect to us
        $ferm_directors.each |$ferm_director| {
            ferm::service { "bacula-file-daemon-${ferm_director}":
                proto  => 'tcp',
                port   => '9102',
                srange => "(@resolve(${ferm_director}) @resolve(${ferm_director}, AAAA))",
            }
        }
    }
}

