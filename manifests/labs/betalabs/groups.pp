class labs::betalabs::groups {

	# That group is the pendant of wikidev for "deptest", it is not
	# defined in LDAP and users have to be manually added to it.
	class devops {
		group { "devops":
			name => "devops",
			gid => 1075,
			ensure => "present",
			allowdupe => false;
		}
	}

}
