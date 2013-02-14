# Temporary puppetization of interim needs while
# Analytics and ops works together to review and puppetize
# Kraken in the production branch of operations/puppet.
# This file will be deleted soon.


# Syncs an HDFS directory to $rsync_destination via rsync hourly
define misc::analytics::hdfs::sync($hdfs_source, $rsync_destination, $tmpdir = "/tmp") {
	require misc::statistics::user

	$tmp_hdfs_dir = "${tmpdir}/hdfs_sync_${name}.tmp"
	$command = "/bin/rm -rf ${tmp_hdfs_dir} && /usr/bin/hadoop fs -get ${hdfs_source} ${tmp_hdfs_dir} && /usr/bin/rsync -rt ${tmp_hdfs_dir} ${rsync_destination} && /bin/rm -rf ${tmp_hdfs_dir}"

	# Create an hourly cron job to rsync to $rsync_destination.
	cron { "hdfs_sync_${name}":
		command => $command,
		user    => $misc::statistics::user::username,
		minute  => 5,
	}
}