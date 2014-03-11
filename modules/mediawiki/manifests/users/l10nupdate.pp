# mediawiki l10nupdate user
class mediawiki::users::l10nupdate {
	## l10nupdate user
	$authorized_key = 'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAzcA/wB0uoU+XgiYN/scGczrAGuN99O8L7m8TviqxgX9s+RexhPtn8FHss1GKi8oxVO1V+ssABVb2q0fGza4wqrHOlZadcFEGjQhZ4IIfUwKUo78mKhQsUyTd5RYMR0KlcjB4UyWSDX5tFHK6FE7/tySNTX7Tihau7KZ9R0Ax//KySCG0skKyI1BK4Ufb82S8wohrktBO6W7lag0O2urh9dKI0gM8EuP666DGnaNBFzycKLPqLaURCeCdB6IiogLHiR21dyeHIIAN0zD6SUyTGH2ZNlZkX05hcFUEWcsWE49+Ve/rdfu1wWTDnourH/Xm3IBkhVGqskB+yp3Jkz2D3Q== l10nupdate@fenari'

	# On labs l10nupdate user and group are already in LDAP
	if $::realm != 'labs' {
		require groups::l10nupdate

		generic::systemuser { 'l10nupdate':
			name          => 'l10nupdate',
			home          => '/home/l10nupdate',
			uid           => $uid,
			default_group => 'l10nupdate',
			shell         => '/bin/bash',
            before        => '/home/l10nupdate/.ssh',
		}
	} else {
        file { '/home/l10update':
			owner  => 'l10nupdate',
			group  => 'l10nupdate',
			mode   => '0750',
			ensure => directory,
            before => '/home/l10nupdate/.ssh',
        }
    }

	file {
		'/home/l10nupdate/.ssh':
			owner  => 'l10nupdate',
			group  => 'l10nupdate',
			mode   => '0500',
			ensure => directory;
		'/home/l10nupdate/.ssh/authorized_keys':
			require => File['/home/l10nupdate/.ssh'],
			owner   => 'l10nupdate',
			group   => 'l10nupdate',
			mode    => '0400',
			content => $authorized_key;
	}
}
