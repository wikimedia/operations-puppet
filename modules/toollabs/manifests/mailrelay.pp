# Class: toollabs::mailrelay
#
# This role sets up a mail relay in the Tool Labs model.
#
# Parameters:
#
# Actions:
#
# Requires:
#  - Hiera: toollabs::is_mail_relay: true
#
# Sample Usage:
#
class toollabs::mailrelay inherits toollabs
{
    include gridengine::submit_host,
            toollabs::infrastructure

    class { 'exim4':
        queuerunner => 'combined',
        config      => template("toollabs/exim4.conf.erb"),
        variant     => 'heavy',
        require     => File['/usr/local/sbin/localuser',
                            '/usr/local/sbin/maintainers'],
    }

    file { "${toollabs::store}/mail-relay":
        ensure  => absent,
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

    # Diamond user needs sudo to access exim
    sudo::user { 'diamond_sudo_for_exim':
        user       => 'diamond',
        privileges => ['ALL=(root) NOPASSWD: /usr/sbin/exim']
    }

    diamond::collector { 'Exim':
        settings     => {
            use_sudo => 'true', # used in a template, not a puppet bool
        }
    }
}
