class wmrole::exim::mediawiki {
	class { exim:
		outbound_ips => [ "208.80.154.4", "2620:0:861:1::2" ],
		local_domains => [ "+system_domains", "+mailman_domains" ],
		enable_mail_relay => "secondary",
		enable_mailman => "true",
		enable_mail_submission => "false",
		enable_spamassassin => "true"
	}
}
