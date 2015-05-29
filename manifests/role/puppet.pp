# == Class role::puppet::self
# Wrapper class for puppet::self::master
# and puppet::self::client.
# If $::puppetmaster is localhost or matches the $::fqdn of this node,
# then this node will be configured as a puppetmaster.
# NOTE:  $::puppetmaster == 'localhost' (or undef) does the exact same
# thing as the original puppetmaster::self class used to do.
#
# $::puppetmaster must be set as a global variable.
# This allows puppet classes to be configured via LDAP
# and wikitech instance configuration.
#
class role::puppet::self(
    $master = $::puppetmaster,
    $autoupdate_master = $::puppetmaster_autoupdate,
    $enc = 'ldap', # 'ldap' or 'yaml+ldap'
) {
    # If $::puppetmaster is not set, assume
    # this is a self hosted puppetmaster, not allowed
    # to serve any other puppet clients.
    $server = $master ? {
          undef       => 'localhost',
          'localhost' => 'localhost',
          ''          => 'localhost',
          # if has . characters in in, assume fqdn.
          /\./        => $master,
          # else assume short hostname and append domain.
          default     => "${master}.${::domain}",
    }

    # If localhost or if $server matches this node's
    # $fqdn, then this is a puppetmaster.
    if ($server == 'localhost' or $server == $::fqdn) {
        if $enc == 'yaml+ldap' {
            $enc_script_path = '/usr/local/bin/ldap-yaml-enc.py'
            file { $enc_script_path:
                source => 'puppet:///modules/puppetmaster/ldap-yaml-enc.py',
                owner  => 'root',
                group  => 'root',
                mode   => '0555',
            }
        }
        class { 'puppet::self::master':
            server          => $server,
            enc_script_path => $enc_script_path,
        }
        # If this parameter / variable variable is set, then
        # run a cron job that automatically tries to update the local
        # git repository, while trying to keep intact cherry picks
        if $autoupdate_master {
            include puppetmaster::gitsync
        }
    }
    # Else this is a puppet client.
    else {
        class { 'puppet::self::client':
            server => $server,
        }
    }
}
