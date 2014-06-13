#  Production RT
class role::rt {
	system::role { 'role::rt': description => 'RT' }

	include passwords::misc::rt

	install_certificate { 'rt.wikimedia.org': }

	class { 'misc::rt':
		site   => 'rt.wikimedia.org',
		dbhost => 'db1001.eqiad.wmnet',
		dbport => '',
		dbuser => $passwords::misc::rt::rt_mysql_user,
		dbpass => $passwords::misc::rt::rt_mysql_pass,
	}

	class { 'exim::roled':
		local_domains          => [ '+system_domains', '+rt_domains' ],
		enable_mail_relay      => false,
		enable_external_mail   => true,
		smart_route_list       => [
			'mchenry.wikimedia.org',
			'lists.wikimedia.org',
		],
		enable_mailman         => false,
		rt_relay               => true,
		enable_mail_submission => false,
		enable_spamassassin    => false,
	}

    # allow RT to receive mail from mchenry and sodium
    ferm::service { 'rt-smtp':
        port   => '25',
        proto  => 'tcp',
        srange => '(208.80.152.186/32 208.80.154.61/32)',
    }

    ferm::service { 'rt-http':
        proto => 'tcp',
        port  => '80',
    }
    ferm::service { 'rt-https':
        proto => 'tcp',
        port  => '443',
    }

}

#  Labs/testing RT
class role::rt::labs {
	system::role { 'role::rt': description => 'RT (Labs)' }

	include passwords::misc::rt

	# FIXME: needs to reference a wmflabs certificate?
	install_certificate { 'rt.wikimedia.org': }

	$datadir = "/srv/mysql"

	class { 'misc::rt':
		site    => $::fqdn,
		dbuser  => $passwords::misc::rt::rt_mysql_user,
		dbpass  => $passwords::misc::rt::rt_mysql_pass,
		datadir => $datadir,
	}

	class { 'mysql::server':
		config_hash => {
			'datadir' => $datadir,
		}
	}

	exec { 'rt-db-initialize':
		command => "/bin/echo '' | /usr/sbin/rt-setup-database --action init --dba root --prompt-for-dba-password",
		unless  => '/usr/bin/mysqlshow rt4',
		require => Class['misc::rt', 'mysql::server'],
	}
}

