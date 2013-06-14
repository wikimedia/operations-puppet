class wmrole::exim::rt {
	class { exim:
		local_domains => [ "+system_domains", "+rt_domains" ],
		enable_mail_relay => "false",
		enable_external_mail => "true",
		smart_route_list => [ "mchenry.wikimedia.org", "lists.wikimedia.org" ],
			enable_mailman => "false",
		rt_relay => "true",
		enable_mail_submission => "false",
		enable_spamassassin => "false"
	}
}
