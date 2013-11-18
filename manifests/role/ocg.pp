# vim: set ts=4 et sw=4:
# role/ocg.pp
# offline content generator

# Virtual resources for the monitoring server
@monitor_group { "ocg_eqiad": description => "offline content generator eqiad" }

class role::ocg {
    system::role { "ocg": description => "offline content generator" }

	package {
		[ 'nodejs' ]:
			ensure => latest;
	}
}
