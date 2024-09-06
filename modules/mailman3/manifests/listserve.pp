# SPDX-License-Identifier: Apache-2.0
# == Class mailman3::listserve
#
# This class provisions all the resources necessary to
# run the core Mailman service.
#
# https://docs.mailman3.org/projects/mailman/en/latest/README.html
#
class mailman3::listserve (
    Stdlib::Fqdn $host,
    Stdlib::Fqdn $db_host,
    String $db_name,
    String $db_user,
    String $db_password,
    String $api_password,
    Wmflib::Ensure $service_ensure = 'present',
    Boolean $allow_incoming_mail = true,
    Stdlib::Unixpath $mailman_root = '/var/lib/mailman3',
) {
    ensure_packages([
        'python3-pymysql',
        'python3-mailman-hyperkitty',
    ])

    $mailman3_debs = [
        'mailman3',
        'python3-authheaders',
        'python3-falcon',
        'python3-flufl.bounce',
        'python3-flufl.lock',
        'python3-importlib-resources',
        'python3-zope.interface',
    ]

    # Use stock mailman3 in bookworm and newer
    ensure_packages($mailman3_debs)

    Package['dbconfig-no-thanks'] ~> Package['mailman3']

    file { '/etc/mailman3/mailman.cfg':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('mailman3/mailman.cfg.erb'),
    }

    service { 'mailman3':
        ensure    => stdlib::ensure($service_ensure, 'service'),
        pattern   => 'mailmanctl',
        subscribe => File['/etc/mailman3/mailman.cfg'],
    }

    if $service_ensure == 'present' {
        systemd::unmask { 'mailman3.service': }
    } else {
        systemd::mask { 'mailman3.service': }
    }

    file { '/etc/logrotate.d/mailman3':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/mailman3/logrotate.conf',
        require => Package['mailman3'],
    }

    # Helper scripts
    file { '/usr/local/sbin/remove_from_lists':
        ensure => 'present',
        owner  => 'root',
        group  => 'list',
        mode   => '0550',
        source => 'puppet:///modules/mailman3/scripts/remove_from_lists.py',
    }

    file { '/usr/local/sbin/discard_held_messages':
        ensure => 'present',
        owner  => 'root',
        group  => 'list',
        mode   => '0550',
        source => 'puppet:///modules/mailman3/scripts/discard_held_messages.py',
    }

    systemd::timer::job { 'discard_held_messages':
        ensure      => $service_ensure,
        user        => 'root',
        description => 'discard un-moderated held messages after 90 days (T109838)',
        command     => '/usr/local/sbin/discard_held_messages 90',
        interval    => {'start' => 'OnCalendar', 'interval' => 'daily'},
    }

    file { '/usr/local/sbin/migrate_to_mailman3':
        ensure => 'present',
        owner  => 'root',
        group  => 'list',
        mode   => '0550',
        source => 'puppet:///modules/mailman3/scripts/migrate_to_mailman3.py',
    }

    file { "${$mailman_root}/templates/domains/":
        ensure => directory,
        owner  => 'root',
        group  => 'list',
        mode   => '0555',
    }

    file { "${$mailman_root}/templates/domains/${host}/":
        ensure  => directory,
        owner   => 'root',
        group   => 'list',
        mode    => '0555',
        require => File["${$mailman_root}/templates/domains/"],
    }

    file { "${$mailman_root}/templates/domains/${host}/en/":
        ensure  => directory,
        owner   => 'root',
        group   => 'list',
        mode    => '0555',
        require => File["${$mailman_root}/templates/domains/${host}/"],
    }

    $templates = [
        'domain_admin_notice_new-list.txt',
        'help.txt',
        'list_admin_action_post.txt',
        'list_admin_action_subscribe.txt',
        'list_admin_action_unsubscribe.txt',
        'list_admin_notice_disable.txt',
        'list_admin_notice_removal.txt',
        'list_admin_notice_subscribe.txt',
        'list_admin_notice_unrecognized.txt',
        'list_admin_notice_unsubscribe.txt',
        'list_member_digest_header.txt',
        'list_member_digest_masthead.txt',
        'list_member_generic_footer.txt',
        'list_member_regular_header.txt',
        'list_user_action_invite.txt',
        'list_user_action_subscribe.txt',
        'list_user_action_unsubscribe.txt',
        'list_user_notice_goodbye.txt',
        'list_user_notice_hold.txt',
        'list_user_notice_no-more-today.txt',
        'list_user_notice_post.txt',
        'list_user_notice_probe.txt',
        'list_user_notice_refuse.txt',
        'list_user_notice_rejected.txt',
        'list_user_notice_warning.txt',
        'list_user_notice_welcome.txt'
    ]

    $templates.each |String $template| {
        $dest_filename = regsubst($template, /_/, ':', 'G')
        file { "${$mailman_root}/templates/domains/${host}/en/${dest_filename}":
            ensure  => file,
            source  => "puppet:///modules/mailman3/templates/${template}",
            owner   => 'root',
            group   => 'list',
            mode    => '0555',
            require => File["${$mailman_root}/templates/domains/${host}/en"],
        }
    }

    firewall::service { 'mailman-smtp':
        ensure => stdlib::ensure($allow_incoming_mail),
        proto  => 'tcp',
        port   => 25,
    }
}
