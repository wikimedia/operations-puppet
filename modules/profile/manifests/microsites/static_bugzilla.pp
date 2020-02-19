# static HTML archive of old Bugzilla tickets
class profile::microsites::static_bugzilla {

    include ::bugzilla_static

    backup::set { 'bugzilla-static' : }

    monitoring::service { 'static-bugzilla-https':
        description   => 'Static Bugzilla HTTPS',
        check_command => 'check_https_url!static-bugzilla.wikimedia.org!/bug1.html',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Bugzilla',
    }
}
