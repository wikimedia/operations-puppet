# application server required cron jobs
class applicationserver::cron {
	cron {
		"cleanupipc":
			command => "ipcs -s | grep apache | cut -f 2 -d \\  | xargs -rn 1 ipcrm -s",
			user => root,
			minute => 26,
			ensure => present;
		"cleantmpphp":
			command => "find /tmp -name 'php*' -type f -ctime +1 -exec rm -f {} \\;",
			user => root,
			hour => 5,
			minute => 0,
			ensure => present;
		"bug55541":   # Hack! Fix the bug and kill this job. --Ori
			command => 'find /tmp -name \*.tif -mmin +60  -delete',
			user => root,
			minute => 34,
			ensure => present;
	}
}