# static HTML archive of old Bugzilla tickets
class profile::microsites::static_bugzilla {

    include ::bugzilla_static

    backup::set { 'bugzilla-static' : }
    backup::set { 'bugzilla-backup' : }

    monitoring::service { 'static-bugzilla-http':
        description   => 'Static Bugzilla HTTP',
        check_command => 'check_http_url!static-bugzilla.wikimedia.org!/bug1.html',
    }

    rsync::quickdatacopy { 'srv-org-wikimedia-static-bugzilla':
      ensure      => absent,
      auto_sync   => false,
      source_host => 'vega.codfw.wmnet',
      dest_host   => 'bromine.eqiad.wmnet',
      module_path => '/srv/org/wikimedia/static-bugzilla',
    }
}
