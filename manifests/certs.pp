define create_pkcs12( $certname="$name", $cert_alias="", $password="", $user="root", $group="ssl-cert", $location="/etc/ssl/private" ) {

	if ( $cert_alias == "" ) {
		$certalias = $certname
	} else {
		$certalias = $cert_alias
	}

	if ( $password == "" ) {
		$defaultpassword = $passwords::certs::certs_default_pass
	} else {
		$defaultpassword = $password
	}

	exec {
		# pkcs12 file, used by things like opendj, nss, and tomcat
		"${name}_create_pkcs12":
			creates => "${location}/${certname}.p12",
			command => "/usr/bin/openssl pkcs12 -export -name \"${certalias}\" -passout pass:${defaultpassword} -in /etc/ssl/certs/${certname}.pem -inkey /etc/ssl/private/${certname}.key -out ${location}/${certname}.p12",
			require => [Package["openssl"], File["/etc/ssl/private/${certname}.key", "/etc/ssl/certs/${certname}.pem"]];
	}

	file {
		# Fix permissions on the p12 file, and make it available as
		# a puppet resource
		"${location}/${certname}.p12":
			mode => 0440,
			owner => $user,
			group => $group,
			require => Exec["${name}_create_pkcs12"],
			ensure => file;
	}
}

define create_chained_cert( $certname="$name", $ca, $user="root", $group="ssl-cert", $location="/etc/ssl/certs" ) {
	exec {
		# chained cert, used when needing to provide an entire certificate chain to a client
		"${name}_create_chained_cert":
			creates => "${location}/${certname}.chained.pem",
			command => "/bin/cat ${certname}.pem ${ca} > ${location}/${certname}.chained.pem",
			cwd => "/etc/ssl/certs",
			require => [Package["openssl"], File["/etc/ssl/certs/${certname}.pem"]];
	}

	file {
		# Fix permissions on the chained file, and make it available as
		# a puppet resource
		"${location}/${certname}.chained.pem":
			mode => 0444,
			owner => $user,
			group => $group,
			require => Exec["${name}_create_chained_cert"],
			ensure => file;
	}
}

define create_combined_cert( $certname="$name", $user="root", $group="ssl-cert", $location="/etc/ssl/private" ) {

	exec {
		# combined cert, used by things like lighttp and nginx
		"${name}_create_combined_cert":
			creates => "${location}/${certname}.pem",
			command => "/bin/cat /etc/ssl/certs/${certname}.pem /etc/ssl/private/${certname}.key > ${location}/${certname}.pem",
			require => [Package["openssl"], File["/etc/ssl/private/${certname}.key", "/etc/ssl/certs/${certname}.pem"]];
	}

	file {
		# Fix permissions on the combined file, and make it available as
		# a puppet resource
		"${location}/${certname}.pem":
			mode => 0440,
			owner => $user,
			group => $group,
			require => Exec["${name}_create_combined_cert"],
			ensure => file;
	}
}

define create_certificate_hash( $certname="$name", $location="/etc/ssl/certs", $hash ) {

	if versioncmp($lsbdistrelease, "11.04") > 0 {
		$hashflag = "-subject_hash_old"
	} else {
		$hashflag = "-subject_hash"
	}
	exec {
		"/bin/ln -s ${location}/${certname}.pem ${location}/$(/usr/bin/openssl x509 ${hashflag} -noout -in ${location}/${certname}.pem).0":
			creates => "${location}/${hash}",
			require => File["${location}/${certname}.pem"];
	}

}

class certs::groups::ssl-cert {
	# Hardy doesn't have system group ssl-cert, so ensure it exists
	if $lsbdistid == "Ubuntu" and versioncmp($lsbdistrelease, "10.04") < 0 {
		group { "ssl-cert":
			system => true,
			ensure => present
		}
	}
}
define install_certificate( $group="ssl-cert", $ca="", $privatekey="true" ) {

	require certificates::packages,
		certificates::rapidssl_ca,
		certificates::digicert_ca,
		certificates::wmf_ca,
		certs::groups::ssl-cert

	if ( $privatekey == "false" ) {
		$key_loc = "puppet:///files/ssl/${name}"
	} else {
		$key_loc = "puppet:///private/ssl/${name}"
	}

	file {
		# Public key
		"/etc/ssl/certs/${name}.pem":
			owner => root,
			group => $group,
			mode => 0444,
			source => "puppet:///files/ssl/${name}.pem",
			require => Package["openssl"];
		# Private key
		"/etc/ssl/private/${name}.key":
			owner => root,
			group => $group,
			mode => 0440,
			source => "${key_loc}.key",
			require => Package["openssl"];
	}

	exec {
		# Many services require certificates to be found by a hash in
		# the certs directory
		"${name}_create_hash":
			unless => "/usr/bin/[ -f \"/etc/ssl/certs/$(/usr/bin/openssl x509 -hash -noout -in /etc/ssl/certs/${name}.pem).0\" ]",
			command => "/bin/ln -s /etc/ssl/certs/${name}.pem /etc/ssl/certs/$(/usr/bin/openssl x509 -hash -noout -in /etc/ssl/certs/${name}.pem).0",
			require => [Package["openssl"], File["/etc/ssl/certs/${name}.pem"]];
	}

	create_pkcs12{ "${name}": }
	create_combined_cert{ "${name}": }
	if ( $ca ) {
		$cas = $ca
	} else {
		# PEM files should be listed in order: intermediate -> intermediate -> ... -> root
		# If this is out of order either servers will fail to start, or will not properly
		# have SSL enabled.
		$cas = $name ? {
			"star.wikimedia.org" => "Equifax_Secure_CA.pem",
			"star.wikipedia.org" => "RapidSSL_CA.pem GeoTrust_Global_CA.pem",
			"test-star.wikipedia.org" => "DigiCertHighAssuranceCA-3.pem DigiCert_High_Assurance_EV_Root_CA.pem",
			"star.wiktionary.org" => "RapidSSL_CA.pem GeoTrust_Global_CA.pem",
			"star.wikiquote.org" => "RapidSSL_CA.pem GeoTrust_Global_CA.pem",
			"star.wikibooks.org" => "RapidSSL_CA.pem GeoTrust_Global_CA.pem",
			"star.wikisource.org" => "RapidSSL_CA.pem GeoTrust_Global_CA.pem",
			"star.wikinews.org" => "RapidSSL_CA.pem GeoTrust_Global_CA.pem",
			"star.wikiversity.org" => "RapidSSL_CA.pem GeoTrust_Global_CA.pem",
			"star.mediawiki.org" => "RapidSSL_CA.pem GeoTrust_Global_CA.pem",
			"star.wikimediafoundation.org" => "RapidSSL_CA.pem GeoTrust_Global_CA.pem",
			"star.wmflabs.org" => "wmf-labs.pem",
			"star.wmflabs" => "wmf-labs.pem",
			default => "wmf-ca.pem",
		}
	}
	create_chained_cert{ "${name}": ca => $cas }

}

define install_additional_key( $key_loc="", $owner="root", $group="ssl-cert", $mode="0440" ) {

	if ( $key_loc ) {
		file {
			"${key_loc}/${name}.key":
				owner => $owner,
				group => $group,
				mode => $mode,
				source => "puppet:///private/ssl/${name}.key",
				require => Package["openssl"];
		}
	}
}

class certificates::packages {

	package { [ "openssl", "ca-certificates", "ssl-cert" ]:
		ensure => latest;
	}

}

class certificates::star_wmflabs_org {

	install_certificate{ "star.wmflabs.org": }

}

class certificates::star_wmflabs {

	install_certificate{ "star.wmflabs": }

}

# DO NOT USE THIS CLASS; TODO: delete
class certificates::star_wikimedia_org {

	include certificates::packages

	file {
		"/etc/ssl/private/*.wikimedia.org.key":
			owner => root,
			group => root,
			mode => 0400,
			source => "puppet:///private/ssl/*.wikimedia.org.key",
			require => Package["openssl"];
		"/etc/ssl/private/*.wikimedia.org.pem":
			owner => root,
			group => root,
			mode => 0400,
			source => "puppet:///private/ssl/*.wikimedia.org.pem",
			require => Package["openssl"];
		"/etc/ssl/certs/*.wikimedia.org.crt":
			owner => root,
			group => root,
			mode => 0444,
			source => "puppet:///files/ssl/*.wikimedia.org.crt",
			require => Package["openssl"];
	}

	exec {
		'/bin/ln -s /etc/ssl/certs/\*.wikimedia.org.crt /etc/ssl/certs/$(/usr/bin/openssl x509 -hash -noout -in /etc/ssl/certs/\*.wikimedia.org.crt).0':
			creates => "/etc/ssl/certs/d5663e04.0",
			require => File["/etc/ssl/certs/*.wikimedia.org.crt"];
	}

}

class certificates::wmf_ca {

	include certificates::packages

	file {
		"/etc/ssl/certs/wmf-ca.pem":
			owner => root,
			group => root,
			mode => 0444,
			source => "puppet:///files/ssl/wmf-ca.pem",
			require => Package["openssl"];
	}

	create_certificate_hash { "wmf-ca": hash => "13b97b27.0" }

}

class certificates::wmf_labs_ca {

	include certificates::packages

	file {
		"/etc/ssl/certs/wmf-labs.pem":
			owner => root,
			group => root,
			mode => 0444,
			source => "puppet:///files/ssl/wmf-labs.pem",
			require => Package["openssl"];
	}

	create_certificate_hash { "wmf-labs": hash => "d693bcb4.0" }

}

class certificates::rapidssl_ca {

	include certificates::packages

	file {
		"/etc/ssl/certs/RapidSSL_CA.pem":
			owner => root,
			group => root,
			mode => 0444,
			source => "puppet:///files/ssl/RapidSSL_CA.pem",
			require => Package["openssl"];
	}

	exec {
		'/bin/ln -s /etc/ssl/certs/RapidSSL_CA.pem /etc/ssl/certs/$(/usr/bin/openssl x509 -hash -noout -in /etc/ssl/certs/RapidSSL_CA.pem).0':
			creates => "/etc/ssl/certs/13b97b27.0",
			require => File["/etc/ssl/certs/RapidSSL_CA.pem"];
	}
	create_certificate_hash { "RapidSSL_CA": hash => "13b97b27.0" }

}

class certificates::digicert_ca {

	include certificates::packages

	file {
		"/etc/ssl/certs/DigiCertHighAssuranceCA-3.pem":
			owner => root,
			group => root,
			mode => 0444,
			source => "puppet:///files/ssl/DigiCertHighAssuranceCA-3.pem",
			require => Package["openssl"];
	}

	exec {
		'/bin/ln -s /etc/ssl/certs/DigiCertHighAssuranceCA-3.pem /etc/ssl/certs/$(/usr/bin/openssl x509 -hash -noout -in /etc/ssl/certs/DigiCertHighAssuranceCA-3.pem).0':
			creates => "/etc/ssl/certs/1445ed77.0",
			require => File["/etc/ssl/certs/DigiCertHighAssuranceCA-3.pem"];
	}
}
