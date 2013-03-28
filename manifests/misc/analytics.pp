# Temporary puppetization of interim needs while
# Analytics and ops works together to review and puppetize
# Kraken in the production branch of operations/puppet.
# This file will be deleted soon.


# Syncs an HDFS directory to $rsync_destination via rsync hourly
define misc::analytics::hdfs::sync($hdfs_source, $rsync_destination, $tmp_dir = "/a/hdfs_sync.tmp") {
	require misc::statistics::user

	file { $tmp_dir:
		ensure => directory,
		owner  => $misc::statistics::user::username,
	}

	$local_tmp_dir = "${tmp_dir}/${name}"
	$command       = "/bin/rm -rf ${local_tmp_dir} && /usr/bin/hadoop fs -get ${hdfs_source} ${local_tmp_dir} && /usr/bin/rsync -rt --delete ${local_tmp_dir}/ ${rsync_destination} && /bin/rm -rf ${local_tmp_dir}"

	# Create an hourly cron job to rsync to $rsync_destination.
	cron { "hdfs_sync_${name}":
		command => $command,
		user    => $misc::statistics::user::username,
		minute  => 15,
		require => File[$tmp_dir],
	}
}


# Temporary class to manage udp2log instances 
# on analytics nodes.  This class will be refactored
# and deleted soon.
# 
# analytics udp2log instances currently shard the
# webrequest stream into $producer_count pieces.
# $producer_id tells the current node which shard
# it is responsible for.
class misc::analytics::udp2log::webrequest($producer_id, $producer_count) {
	include misc::udp2log,
		misc::udp2log::utilities

	# Starts a multicast listening udp2log instance
	# to read from the webrequest log stream.
	misc::udp2log::instance { "webrequest":
		port                => "8420",
		multicast           => true,
		log_directory       => "/var/log/udp2log/webrequest",
		logrotate           => false,
		monitor_packet_loss => true,
		monitor_processes   => true,
		monitor_log_age     => false,
		template_variables  => {
			'producer_count' => $producer_count,
			'producer_id'    => $producer_id,
		}
	}
}

