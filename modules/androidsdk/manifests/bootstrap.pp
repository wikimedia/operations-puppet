# Android SDK

# Download and install Android SDK from Google whenever
# it is not already deployed.

class androidsdk::bootstrap {

	# Directory where everything happens
	$base_directory = "/opt/androidsdk"

	# Directory where the first SDK will be downloaded and extracted:
	$bootstrap_directory = "/opt/androidsdk/bootstrap"

	# Which version to get for our first installation. Should be updated
	# from time to time http://developer.android.com/sdk/index.html
	$bootstrap_version = "r20.0.3"

	# Filename and URL to the SDK download file:
	$bootstrap_filename = "android-sdk_${bootstrap_version}-linux.tgz"
	$bootstrap_url = "http://dl.google.com/android/${bootstrap_filename}"

	# Where the SDK will be downloaded to:
	$bootstrap_archive = "${bootstrap_directory}/${bootstrap_filename}"

	# Base definitions:

	package { ['curl']: ensure => present; }

	file { $base_directory:
		ensure => directory;
	}

	file { $bootstrap_directory:
		ensure => directory,
		require => File[$base_directory];
	}

	exec { "extract_bootstrap_archive":
		cwd => $bootstrap_directory,
		command => "tar -xzf ${bootstrap_archive}",
		creates => "${bootstrap_directory}/android-sdk-linux_x86",
		require => Exec["download_bootstrap_version"];
	}

	exec { "download_bootstrap_version":
		cwd => $bootstrap_directory,
		command => "curl '${bootstrap_url}' --output '${bootstrap_archive}'",
		creates => $bootstrap_archive,
		require => [
			File[$boostrap_directory],
			Package['curl'],
		];
	}

}
