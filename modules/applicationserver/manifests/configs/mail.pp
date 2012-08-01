# Configuration files for sending mail from an application servers
#
# requires applicationserver::packages to be in place
class applicationserver::config::mail {

	require applicationserver::packages

	file {
		"/etc/php5/conf.d/mail.ini":
			mode => 0444,
			owner => root,
			group => root,
			content => "
// Force the envelope sender address to empty, since we don't want to receive bounces
mail.force_extra_parameters=\"-f <>\"
";
	}
}