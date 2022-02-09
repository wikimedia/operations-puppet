# Cleanup whisper directories from old metric files
#
# === Parameters
#
# [*directory*] The directory to cleanup
# [*keep_days*] Files older than this many days will be deleted
# [*user*] Username to run the commands as

define graphite::whisper_cleanup (
  $directory,
  $keep_days = 30,
  $user = '_graphite',
) {
    $hour = fqdn_rand(24, $title)
    $minute = fqdn_rand(60, $title)

    systemd::timer::job { $title:
        ensure      => present,
        description => 'Regular jobs for cleanup of whisper directories',
        user        => $user,
        command     => "/usr/local/bin/whisper-cleanup ${directory} ${keep_days}",
        interval    => {'start' => 'OnCalendar', 'interval' => "*-*-* ${hour}:${minute}:00"},
        require     => [
            File['/usr/local/bin/whisper-cleanup']
        ],
    }
}
