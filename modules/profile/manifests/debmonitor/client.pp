# Class: profile::debmonitor::client
# @summary
# This profile installs the Debmonitor client and its configuration.
#
# Actions:
#       Expose Puppet certs for the debmonitor user
#       Install DebMonitor client's configuration
#       Install DebMonitor client
#
# Sample Usage:
#       include ::profile::debmonitor::client
# @param debmonitor_server the main debmonitor server
# @param ensure ensureable parameter
# @param ssl_ca use the puppet issued certs or request a cert from cfssl
# @param ssl_ca_label if using cfssl this is the ca label to use for certificate requests
class profile::debmonitor::client (
    Stdlib::Host            $debmonitor_server = lookup('debmonitor'),
    Wmflib::Ensure          $ensure            = lookup('profile::debmonitor::client::ensure'),
    Enum['puppet', 'cfssl'] $ssl_ca            = lookup('profile::debmonitor::client::ssl_ca'),
    Optional[String]        $ssl_ca_label      = lookup('profile::debmonitor::client::ssl_ca_label'),
) {

    $base_path = '/etc/debmonitor'

    # On Debmonitor server hosts this is already defined by service::uwsgi.
    if !defined(File[$base_path]) {
        # Create directory for the exposed Puppet certs.
        file { $base_path:
            ensure => stdlib::ensure($ensure, 'directory'),
            owner  => 'debmonitor',
            group  => 'debmonitor',
            mode   => '0555',
        }
    }

    # Create user and group to which expose the Puppet certs.
    group { 'debmonitor':
        ensure => $ensure,
        system => true,
    }

    user { 'debmonitor':
        ensure     => $ensure,
        gid        => 'debmonitor',
        shell      => '/bin/bash',
        home       => '/nonexistent',
        managehome => false,
        system     => true,
        comment    => 'DebMonitor system user',
    }

    if $ssl_ca == 'puppet' {
        # TODO: consider using profile::pki::get_cert
        puppet::expose_agent_certs { $base_path:
            ensure          => $ensure,
            user            => 'debmonitor',
            group           => 'debmonitor',
            provide_private => true,
            require         => File[$base_path],
            before          => Package['debmonitor-client'],
        }

        $cert = "${base_path}/ssl/cert.pem"
        $private_key = "${base_path}/ssl/server.key"
    } else {
        unless $ssl_ca_label {
            fail('must specify \$ssl_label when using \$ssl_ca == \'cfssl\'')
        }
        $ssl_paths = profile::pki::get_cert($ssl_ca_label, $facts['networking']['fqdn'], {
            ensure => $ensure,
            owner  => 'debmonitor',
            group  => 'debmonitor',
            outdir => "${base_path}/ssl",
            before => Package['debmonitor-client']
        })
        $cert        = $ssl_paths['cert']
        $private_key = $ssl_paths['key']
    }

    # Create the Debmonitor client configuration file.
    file { '/etc/debmonitor.conf':
        ensure  => stdlib::ensure($ensure, file),
        owner   => 'debmonitor',
        group   => 'debmonitor',
        mode    => '0440',
        content => template('profile/debmonitor/client/debmonitor.conf.erb'),
        before  => Package['debmonitor-client'],
    }

    # We have to install debmonitor-client after /etc/debmonitor.conf and the
    # ssl certs are configured. This is due to the fact that:
    #  * during installation we install the debmonitor apt->hook
    #  * post installation we run the apt->hook installed above
    # If the certs and config file are not in place this will fail. The ssl and
    # file resources have an explicit Before statements and we also place the
    # installation here so the manifest order represent the catalogue order
    ensure_packages('debmonitor-client', {'ensure' => $ensure})

    $hour = Integer(seeded_rand(24, $facts['networking']['fqdn']))
    $minute = Integer(seeded_rand(60, $facts['networking']['fqdn']))

    systemd::timer::job { 'debmonitor-client':
        ensure        => $ensure,
        user          => 'debmonitor',
        description   => 'reconciliation job in case any debmonitor update fails',
        command       => '/usr/bin/debmonitor-client',
        send_mail     => true,
        ignore_errors => true,
        interval      => {'start' => 'OnCalendar', 'interval' => "*-*-* ${hour}:${minute}:30"},
        require       => Package['debmonitor-client'],
    }
}
