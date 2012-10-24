# Configuration files for php5 running on application servers
#
# requires applicationserver::packages to be in place
class applicationserver::config::php {

	Class["applicationserver::packages"] -> Class["applicationserver::config::php"]

	file {
		"/etc/php5/apache2/php.ini":
			owner => root,
			group => root,
			mode => 0444,
			source => "puppet:///modules/applicationserver/php/php.ini";
		"/etc/php5/cli/php.ini":
			owner => root,
			group => root,
			mode => 0444,
			source => "puppet:///modules/applicationserver/php/php.ini.cli";
		"/etc/php5/conf.d/fss.ini":
			owner => root,
			group => root,
			mode => 0444,
			source => "puppet:///modules/applicationserver/php/fss.ini";
		"/etc/php5/conf.d/apc.ini":
			owner => root,
			group => root,
			mode => 0444,
			source => "puppet:///modules/applicationserver/php/apc.ini";
		"/etc/php5/conf.d/wmerrors.ini":
			owner => root,
			group => root,
			mode => 0444,
			source => "puppet:///modules/applicationserver/php/wmerrors.ini";
		"/etc/php5/conf.d/igbinary.ini":
			owner => root,
			group => root,
			mode => 0444,
			source => "puppet:///files/php/igbinary.ini";
		"/etc/php5/conf.d/wikidiff2.ini":
			mode => 0444,
			owner => root,
			group => root,
			content => "
; This file is managed by Puppet!
extension=wikidiff2.so
";
		"/etc/php5/conf.d/mail.ini":
			mode => 0444,
			owner => root,
			group => root,
			content => "
// Force the envelope sender address to empty, since we don't want to receive bounces
mail.force_extra_parameters=\"-f <>\"
";
	}

	Class["applicationserver::config::php"] -> Class["applicationserver::config::base"]
}
