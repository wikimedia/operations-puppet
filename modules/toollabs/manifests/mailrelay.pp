# Class: toollabs::mailrelay
#
# This role sets up a mail relay in the Tool Labs model.
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class toollabs::mailrelay($maildomain) inherits toollabs
{
    include gridengine::submit_host,
            toollabs::infrastructure

    # FIXME: -ugly-, we need to have a better way for this
    Package <| title == 'exim4-daemon-light' |> {
        ensure => undef
    }
    package{ 'exim4-daemon-heavy':
        ensure => present
    }

    file { "${toollabs::store}/mail-relay":
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => File[$toollabs::store],
        content => template('toollabs/mail-relay.erb'),
    }

    file { '/usr/local/sbin/localuser':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        source  => 'puppet:///modules/toollabs/localuser',
    }

    file { '/usr/local/sbin/maintainers':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        source  => 'puppet:///modules/toollabs/maintainers',
    }

    File <| title == '/etc/exim4/exim4.conf' |> {
        source  => undef,
        content => template('toollabs/exim4.conf.erb'),
        notify  => Service['exim4'],
        require => File['/usr/local/sbin/localuser',
                        '/usr/local/sbin/maintainers'],
    }

    File <| title == '/etc/default/exim4' |> {
        content => undef,
        source  =>  'puppet:///modules/toollabs/exim4.default.mailrelay',
        notify  => Service['exim4'],
    }

    # Diamond user needs sudo to access exim
    sudo::user { 'diamond_sudo_for_exim':
        user       => 'diamond',
        privileges => ['ALL=(root) NOPASSWD: /usr/sbin/exim']
    }

    diamond::collector:extendedexim {
        settings     => {
            use_sudo => 'true', # used in a template, not a puppet bool
        }
    }
}
