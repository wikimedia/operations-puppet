class profile::toolforge::base(
    $is_mail_relay = hiera('profile::toolforge::is_mail_relay', false),
    $active_mail_relay = hiera('profile::toolforge::active_mail_relay', 'tools-mail-02.tools.eqiad.wmflabs'),
    $mail_domain = hiera('profile::toolforge::mail_domain', 'tools.wmflabs.org'),
) {
    require ::profile::toolforge::clush::target

    package { 'nano':
        ensure => latest,
    }

    alternatives::select { 'editor':
        path => '/bin/nano',
    }

    file { '/root/.bashrc':
        ensure => file,
        source => 'puppet:///modules/profile/toolforge/rootrc',
        owner  => 'root',
        group  => 'root',
        mode   => '0750',
    }

    # Users can choose their shell accounts names freely, and some
    # choose ones that can be misleading to third parties inter alia
    # when they are used to send and receive mail at
    # "$user@tools.wmflabs.org".  The most common ones are already
    # addressed by the default system aliases for "abuse",
    # "postmaster", "webmaster", etc., so we only have to add aliases
    # here that have not been standardized per se, but still bear a
    # high risk of mimicry.
    mailalias { [ 'admin', 'administrator' ]:
        ensure    => present,
        recipient => 'root',
    }

    if !$is_mail_relay {
        class { '::exim4':
            queuerunner => 'combined',
            config      => template('profile/toolforge/route-to-mail-relay.exim4.conf.erb'),
            variant     => 'light',
        }
    }

    # Silence e-mails sent when regular users try to sudo (T95882)
    file { '/etc/sudoers.d/40-tools-sudoers-no-warning':
        ensure => file,
        mode   => '0440',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/profile/toolforge/40-tools-sudoers-no-warning',
    }

    file { '/etc/security/limits.d/50-no-bigfiles.conf':
        ensure => file,
        mode   => '0444',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/profile/toolforge/50-no-bigfiles.conf',
    }

    file { '/usr/local/bin/log-command-invocation':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/profile/toolforge/log-command-invocation',
    }
}
