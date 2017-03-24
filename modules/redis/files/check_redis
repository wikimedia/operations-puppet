#!/usr/bin/perl -w
#
# ============================== SUMMARY =====================================
#
# Program : check_redis.pl
# Version : 0.73
# Date    : Mar 23, 2013
# Author  : William Leibzon - william@leibzon.org
# Licence : GPL - summary below, full text at http://www.fsf.org/licenses/gpl.txt
#
# =========================== PROGRAM LICENSE =================================
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
# ===================== INFORMATION ABOUT THIS PLUGIN =========================
#
# This is Redis Server Check plugin. It gets stats variables and allows to set
# thresholds on their value or their rate of change. It can measure response time,
# hitrate, memory utilization, check replication sync and more. It can also test
# data in a specified key (if necessary doing average or sum on range).
#
# Plugin returns stats variables as performance data for further nagios 2.0
# post-processing, you can find graph templates for PNP4Nagios at:
#   http://william.leibzon.org/nagios/
#
# This program is written and maintained by:
#   William Leibzon - william(at)leibzon.org
#
# ============================= SETUP NOTES ====================================
#
# Make sure to install Redis perl library from CPAN first.
#
# Next for help and to see what parameters this plugin accepts do:
#  ./check_redis.pl --help
#
# This plugin checks Redis NoSQL database status variables, measures its response
# time and if specified allows to set thresholds on one or more key data. You can
# set thresholds for data in stats variables and some of them are also conveniently
# available as long options with special threshold syntax. Plugin also calculates
# statistics such as Hitrate (calculated as rate of change of hits/misses) and
# memory use and can check replication delay.
#
# All variables can be returned as performance data for graphing and pnp4nagios
# template should be available with this plugin on the site you downloaded it from.

# 1. Connection Parameters
#
#   The connection parameters are "-H hostname", "-p port", "-D database" and
#   "-C password_file" or "-x password". Specifying hostname is required, if you
#   run locally specify it as -H 127.0.0.1. Everything else is optional and rarely
#   needed. Default port is 6337. Database name (usually a numeric id) is probably
#   only needed if you use --query option. Password can be passed on a command
#   line with -x but its safer to read read it from a file or change in the code
#   itself if you do use authentication.
#
# 2. Response Time, HitRate, Memory Utilization, Replication Delay
#
#   To get response time you use "-T" or "--response_time=" option. By itself
#   it will cause output of response time at the status line. You can also use
#   it as "-T warn,crit" to specify warning and critical thresholds.
#
#   To get hitrate the option is "-R" or "--hitrate=". If previous performance
#   data is not feed to plugin (-P option, see below) the plugin calculates
#   it as total hitrate over life of redis process. If -P is specified and
#   previous performance data is fed back, the data is based on real hitrate
#   (which can show spikes and downs) with lifelong info also given in paranthesis
#   The data is based on keyspace_hits and keyspace_misses stats variables.
#   As with -T you can specify -R by itself or with thresholds as -R warn,crit
#
#   Memory utilization is percent of real memory used by Redis out of total
#   memory on the system. To be able to calculate it plugin needs to known
#   amount of memory your system has which you specify with "-M" or "--total_memory="
#   option. Memory utilization option itself is lower "-m" or "--memory_utilization="
#   and you can specify threshold for it as "-m warn,crit"
#
#   Replication delay threshold option "-R" or "--replication_delay=" is used
#   to check replication with data from "master_last_io_seconds_ago" stats and
#   valid only on slave servers. Other variables maybe checked for this later
#   with more complex functionality, so it was chosen to do this as separate
#   option rather than directing people to check that variable.
#
# 3. Checks on Redis Status Variables
#
#   All status variables from redis can be checked with the plugin. For some
#   status variables separate long option is provided to specify threshold.
#       i.e. --connected_clients=<thresholds>
#
#   This is a new alternative to specifying all variables together with -a
#   (--variables) option. For example:
#       -a connected_clients,blocked_clients
#   When you do above results are included in status output line and you
#   are required to specify thresholds with -w or --warn and -c or --crit
#   with exactly number of thresholds as a number of variables specified
#   in -a. If you simply want variable values on status line without specifying
#   any threshold, use ~ in place of threshold value or skip value but specify
#   all appropriate commas. For example:
#           -a connected_clients,blocked_clients -w ~,~ -c ~,~
#      OR   -a connected_clients,blocked_clients -w , -c ,
#
#   If you use new syntax with a long option for specific stats variables, you
#   can specify list of one or more threshold specifiers which can be any of:
#       NAME:<string>   - Overrides name for this variable for use in status and PERF output
#       PATTERN:<regex> - Regular Expression that allows to match multiple data results
#       WARN:threshold  - warning alert threshold
#       CRIT:threshold  - critical alert threshold
#         Threshold is a value (usually numeric) which may have the following prefix:
#           > - warn if data is above this value (default for numeric values)
#           < - warn if data is below this value (must be followed by number)
#           = - warn if data is equal to this value (default for non-numeric values)
#           ! - warn if data is not equal to this value
#         Threshold can also be specified as a range in two forms:
#           num1:num2  - warn if data is outside range i.e. if data<num1 or data>num2
#           \@num1:num2 - warn if data is in range i.e. data>=num1 && data<=num2
#       ABSENT:OK|WARNING|CRITICAL|UNKNOWN - Nagios alert (or lock of thereof) if data is absent
#       ZERO:OK|WARNING|CRITICAL|UNKNOWN   - Nagios alert (or lock of thereof) if result is 0
#       DISPLAY:YES|NO - Specifies if data should be included in nagios status line output
#       PERF:YES|NO    - Output in performance data or not (always YES if -F option is used)
#       UOM:<string>   - Unit Of Measurement symbol to add to perf data - 'c','%','s','B'
#			 This is used by programs that graph perf data such as PNP
#
#   These can be specified in any order separated by ",". For example:
#      --connected_clients=CRIT:>100,WARN:>50,ABSENT:CRITICAL,ZERO:OK,DISPLAY:YES,PERF:YES
#
#   Variables that are not known to plugin and don't have specific long option (or even if
#   they do) can be specified using general long option --check or --option or -o
#   (all are aliases for same option):
#      --check=NAME:connected_clients,CRIT:>100,WARN:>50,ABSENT:CRITICAL,DISPLAY:YES,PERF:YES
#
#   Then NAME is used to specify what to match and multiple data vars maybe matched
#   with PATTERN regex option (and please only use PATTERN with --check and not confuse
#   plugin by using it in a named long option). Either NAME or PATTERN are required.
#
# 4. Calculating and using Rate of Change for Variables
#
#   If you want to check rate of change rather than actual value you can do this
#   by specifying it as '&variable' such as "&total_connections_received" or
#   as "variable_rate" which is "total_connections_received_rate" and is similar
#   to 'connected_clients' variable. By default it would be reported in the output
#   as 'variable_rate' though '&variable' is a format used internally by plugin.
#
#   As an alternative you can specify how to label these with --rate_label
#   option where you can specify prefix and/or suffix. For example '--rate_label=dt_'
#   would have the output being "dt_total_connections_received' where as
#   '--rate_label=,_rate' is plugin default giving 'total_connections_received_rate'.
#   You can use these names with -a and -A such as:
#       --rate_label=,_rate -a total_connections_received_rate -w 1000 -c ~
#   Note that --rate_label will not work with new variable-named options, the
#   only way to change default if you use that is to modify code and change
#   $o_rprefix and $o_rsuffix variables default values.
#
#   Now in order to be able to calculate rate of change, the plugin needs to
#   know values of the variables from when it was run the last time. This
#   is done by feeding it previous performance data with a -P option.
#   In commands.cfg this would be specified as:
#     -P "$SERVICEPERFDATA$"
#   And don't forget the quotes, in this case they are not just for documentation.
#
# 5. Threshold Specification
#
#   The plugin fully supports Nagios plug-in specification for specifying thresholds:
#     http://nagiosplug.sourceforge.net/developer-guidelines.html#THRESHOLDFORMAT
#
#   And it supports an easier format with the following one-letter prefix modifiers:
#     >value : issue alert if data is above this value (default for numeric value)
#     <value : issue alert if data is below this value (must be followed by number)
#     =value : issue alert if data is equal to this value (default for non-numeric)
#     !value : issue alert if data is NOT equal to this value
#   (because > and < are interpreted by shell you may need to specify this in quotes)
#   There are also two specifications of range formats as with other nagios plugins:
#     number1:number2   issue alert if data is OUTSIDE of range [number1..number2]
#	                i.e. alert if data<$number1 or data>$number2
#     @number1:number2  issue alert if data is WITHIN range [number1..number2]
#		        i.e. alert if data>=$number and $data<=$number2
#
#   The plugin will attempt to check that WARNING value is less than CRITICAL
#   (or greater for <). A special prefix modifier '^' can be used to disable these
#   checks. A quick example of such special use is '--warn=^<100 --crit=>200' which
#   means warning alert if value is < 100 and critical alert if its greater than 200.
#
# 6. Performance Data
#
#   With '-f' option values of all variables you specified in -a as well as
#      response time from -T (response time),
#      hitrate from -R,
#      memory utilization from -m
#   and other data are reported back out as performance data for Nagios graphing programs.
#
#   You may also directly specify which variables are to be return as performance data
#   with '-A' option. If you use '-A' by itself and not specify any variables or use
#   special value of '*' (as in '-A *') the plugin will output all variables which is useful
#   for finding what data you can check with this plugin.
#
#   The plugin will output threshold values as part of performance data as specified at
#     http://nagiosplug.sourceforge.net/developer-guidelines.html#AEN201
#   And don't worry about using non-standard >,<,=,~ prefixes, all of that would get
#   converted into nagios threshold format for performance output
#
#   The plugin is smart enough to add 'c' suffix for known COUNTER variables to
#   values in performance data. Known variables are specified in an array you can
#   find at the top of the code (further below) and plugin author does not claim
#   to have identified all variables correctly. Please email if you find an error
#   or want to add more variables.
#
#   As noted above performance data is also used to calculate rate of change
#   by feeding it back with -P option. In that regard even if you did not specify
#   -f or -A but you have specified &variable, its actual data would be sent out
#   in performance output. Additionally last time plugin was run is also in
#   performance data as special _ptime variable.
#
# 7. Query Option and setting thresholds for data in Redis Database
#
#   With -q (--query) option the plugin can retrieve data from Redis database
#   which become new variables you can then check thresholds on. Currently it
#   supports getting single key values with GET and getting range or values (or
#   everything in list) with LRANGE and finding their Average or Min or Max or Sum.
#   The option maybe repeated more than once. The format for this option is:
#
#      -q, --query=query_type,key[:varname]<,list of threshold specifiers>
#
#  query_type is one of:
#	GET   - get one string value
#       LLEN  - returns number of items in a list
#	LRANGE:AVG:start:end - retrieve list and average results
#	LRANGE:SUM:start:end - retrieve list and sum results
#	LRANGE:MIN:start:end - retrieve list and return minimum
#	LRANGE:MAX:start:end - retrieve list and return maximum
#       HLEN  - returns number of items in a hash [TODO]
#       HGET:name  - get specific hash key 'name' [TODO]
#       HEXISTS:name - returns 0 or 1 depending on if specified hash key 'name' exists [TODO]
#       SLEN  - returns number of items in a set [TODO, SCARD redis opp]
#       SEXISTS:name - returns 0 or 1 depending on if set member 'name' exists [SISMEMBER, TODO]
#       ZLEN  - returns number of items in a sorted set [TODO, ZCARD redis opp]
#       ZCOUNT:min:max - counts number of items in sorted set with scores within the given values
#       ZRANGE:AVG:min:max - retrieve sorted set members from min to max and average results
#       ZRANGE:SUM:min:max - retrieve sorted set members from min to max and sum results
#       ZRANGE:MIN:min:max - retrieve sorted set members from min to max list and return minimum
#       ZRANGE:MAX:min:max- retrieve sorted set members from min to max and return maximum
#   For LRANGE if you do not specify start and end, then start will be  0 and end
#   is last value in the list pointed to by this key (found by using llen).
#
#   Key is the Redis key name to be retrieved and optionally you can add ":varname"
#   after it which specifies what to name plugin variable based on this data -
#   based on what you specify here is how it will be displayed in the status
#   line and performance data, default is same as Redis key name.
#
#   After these key name you specify list of thresholds in the same format as
#   variable-based long options described in section 3. Again the list of the
#   possible specifiers are:
#      WARN:threshold
#      CRIT:threshold
#      ABSENT:OK|WARNING|CRITICAL|UNKNOWN  - what to do if data is not available
#      ZERO:OK|WARNING|CRIICAL|UNKNOWN	   - what to do if data is 0 (rarely needed)
#      DISPLAY:YES|NO			   - display on status line or not (default YES)
#      PERF:YES|NO	 		   - output in perf data or not
#
#   You can also optionally use -a, -w and -c to check data from the query instead
#   of specifying thresholds as part of query option itself And remember that you if
#   you need to check multiple keys you just repeat --query option more than once.
#
# 8. Example of Nagios Config Definitions
#
# Sample command and service definitions are below:
#
# define command {
#    command_name        check_redis_new
#    command_line        $USER1$/check_redis.pl -H $HOSTADDRESS$ -p $ARG1$ -T $ARG2$ -R -A -M $_HOSTSYSTEM_MEMORY$ -m $ARG3$ -a $ARG4$ -w $ARG5$ -c $ARG6$ -f -P "$SERVICEPERFDATA$"
# }
#
# Arguments and thresholds are:
#  $ARG1 : Port
#  $ARG2 : response time thresholds
#  $ARG3 : memory utilization thresholds
#  $ARG4 : additional variables to be checked
#  $ARG5 : warning thresholds for those variables
#  $ARG6 : critical thresholds for those variables
#
# define service {
#        use                     prod-service
#        hostgroups              redishosts
#        service_description     Redis
#        check_command           check_redis_new!6379!"1,2"!"80,90"!blocked_clients,connected_clients!50,~!100,~
# }
#
# define host {
#         use             prod-server
#         host_name       redis.mynetwork
#         address         redis.mynetwork
#         alias           Redis Stat Server
#         hostgroups      linux,redishosts
#        _SYSTEM_MEMORY  '8G'
# }
#
# Example of command-line use:
#   /usr/lib/nagios/plugins/check_redis.pl -H localhost -a 'connected_clients,blocked_clients' -w ~,~ -c ~,~ -m -M 4G -A -R -T -f -v
#
# In above the -v option means "verbose" and with it plugin will output some debugging information
# about what it is doing. The option is not intended to be used when plugin is called from nagios itself.
#
# Example of using query and variable-based long options with debug enabled as well (-v):
#
# ./check_redis.pl -H localhost -p 6379 -D 1 --query LRANGE:AVG:0:,MyColumn1:Q1,ABSENT:WARNING,WARN:300,CRIT:500,DISPLAY:YES,PERF:NO
#   --query GET,MyKey:K1,ABSENT:CRITICAL "--connected_clients=WARN:<2,CRIT:>100,ZERO:OK,ABSENT:WARNING,DISPLAY:YES,PERF:YES"
#
# ======================= VERSION HISTORY and TODO ================================
#
# The plugins is written by reusing code my check_memcached.pl which itself is based
# on check_mysqld.pl. check_mysqld.pl has history going back to 2004.
#
#  [0.4  - Mar 2012] First version of the code based on check_mysqld.pl 0.93
#		     and check_memcached.pl 0.6. Internal work, not released.
#		     Version 0.4 because its based on a well developed code base
#  [0.41 - Apr 15, 2012] Added list of variables array and perf_ok regex.
#			 Still testing internally and not released yet.
#  [0.42 - Apr 28, 2012] Added total_keys, total_expires, nice uptime_info
#			 and memory utilization
#  [0.43 - May 31, 2012] Release candidate. More documentation added
#			 replacing check_memcached examples. Bugs fixed.
#			 Made "_rate" as default rate variables suffix in
#		         place of &delta. Changed -D option to -r.
#
#  [0.5  - Jun 01, 2012] First official release will start with version 0.5
#			 Documentation changes, but no code updates.
#  [0.51 - Jun 16, 2012] Added support to specify filename to '-v' option
#			 for debug output and '--debug' as alias to '--verbose'
#  [0.52 - Jul 10, 2012] Patch by Jon Schulz to support credentials with -C
#			 (credentials file) and addition by me to support
#			 password as command argument.
#  [0.53 - Jul 15, 2012] Adding special option to do query on one redis key and
#                        and do threshold checking of results if its numeric
#
#  [0.6  - Jul 17, 2012] Rewrote parts of thresholds checking code and moved code
#			 that checks and parses thresholds from main into separate
#			 functions that are to become part of plugin library.
#			 Added support for variable thresholds specified as:
#			   option=WARN:threshold,CRIT:threshold,ABSENT:OK|WARNING|CRITICAL,ZERO:..
#			 which are to be used for stats-variable based long options such as
#			   --connected_clients=WARN:threshold,CRIT:threshold
#			 and added DISPLAY:YES|NO and PERF specifiers for above too.
#			 Added -D option to specify database needed for --query
#  [0.61 - Aug 03, 2012] Added more types of key query for lists, sets, hashes
#			 and options to find number of elements in a list/set/hash.
#		         New options added are:
#			   LLEN,HLEN,SLEN,ZLEN,HGET,HEXISTS,SEXISTS,ZRANGE
#
#  [0.7  - Aug 28, 2012] A lot of internal rewrites in the library. Its now not just a
#		         a set of functions, but a proper object library with internal
#			 variables hidden from outside. Support has also been added for
#		         regex matching with PATTERN specifier and for generalized
#                        --check option that can be used where specific long option is
#			 not available. For use with that option also added UOM specifier.
#		         Also added checkin 'master_last_io_seconds_ago' (when link is down)
#			 for when replication_delay info is requested.
#  [0.71 - Sep 03, 2012] Fixed bug in a new library related to when data is missing
#  [0.72 - Oct 05, 2012] Fixed bug reported by Matt McMillan in specified memory size
#			 when KB are used. Fixed bugs in adding performance data that
# 			 results in keyspace_hits, keyspace_misses, memory_utilization
#			 having double 'c' or '%' in perfdata. Added contributors section.
#  [0.73 - Mar 23, 2013] Fixed bug in parse_threshold function of embedded library
#
# TODO or consider for future:
#
#  1. Library Enhancements (will apply to multiple plugins that share common code)
#     (a) Add '--extra-opts' to allow to read options from a file as specified
#         at http://nagiosplugins.org/extra-opts. This is TODO for all my plugins
#     (b) [DONE]
#	  In plans are to allow long options to specify thresholds for known variables.
#         These would mean you specify '--connected_clients' in similar way to '--hitrate'
#         Internally these would be converged into -A, -w, -c as appropriate and used
#         together with these options. So in practice it will now allow to get any data
#         just a different way to specify options for this plugin.
#     (c) Allow regex when selecting variable name(s) with -a, this will be enabled with
#	  a special option and not be default
#	  [DONE]
#
#  2. REDIS Specific
#     (a) Add option to check from master that slave is connected and working.
#     (b) Look into replication delay from master and how it can be done. Look
#         for into on replication_delay from slave as well
#     (c) How to better calculate memory utilization and get max memory available
#         without directly specifying it
#     (d) Maybe special options to measure cpu use and set thresholds
#
#  Others are welcome recommend a new feature to be added here. If so please email to
#         william@leibzon.org.
#  And don't worry, I'm not a company with some hidden agenda to use your idea
#  but an actual person who you can easily get hold of by email, find on forums
#  and on Nagios conferences. More info on my nagios work is at:
#         http://william.leibzon.org/nagios/
#  Above site should also have PNP4Nagios template for this and other plugins.
#
# ============================ LIST OF CONTRIBUTORS ===============================
#
# The following individuals have contributed code, patches, bug fixes and ideas to
# this plugin (listed in last-name alphabetical order):
#
#   William Leibzon
#   Matthew Litwin
#   Matt McMillan
#   Jon Schulz
#   M Spiegle
#
# ============================ START OF PROGRAM CODE =============================

use strict;
use IO::Socket;
use Time::HiRes;
use Text::ParseWords;
use Getopt::Long qw(:config no_ignore_case);
use Redis;

# default hostname, port, database, user and password, see NOTES above
my $HOSTNAME= 'localhost';
my $PORT=     6379;
my $PASSWORD= undef;
my $DATABASE= undef;

# Add path to additional libraries if necessary
use lib '/usr/lib/nagios/plugins';
our $TIMEOUT;
our %ERRORS;
eval 'use utils qw(%ERRORS $TIMEOUT)';
if ($@) {
 $TIMEOUT = 20;
 %ERRORS = ('OK'=>0,'WARNING'=>1,'CRITICAL'=>2,'UNKNOWN'=>3,'DEPENDENT'=>4);
}

my $Version='0.73';

# This is a list of known stat and info variables including variables added by plugin,
# used in order to designate COUNTER variables with 'c' in perfout for graphing programs
# The format is:
#        VAR_NAME => [ TYPE, PerfSuffix, DESCRIPTION]
# If option has description, the variable will also become available as a long option so for example
# you can specify "--connected_clients=WARN,CRIT" instead of specifying "-a connected_clients -w WARN -c CRIT'
my %KNOWN_STATUS_VARS = (
	 'memory_utilization' => [ 'status', 'GAUGE', '%' ],      					# calculated by plugin
	 'redis_version' => [ 'status', 'VERSION', '' ],						# version string variable
	 'response_time' => [ 'status','GAUGE', 's' ],							# measured by plugin
	 'hitrate' => [ 'status', 'GAUGE', '%' ],							# calculated by plugin
	 'total_keys' => [ 'status','GAUGE', '', 'Total Number of Keys on the Server' ],
	 'total_expires' => [ 'status','GAUGE', '', 'Number of Expired Keys for All DBs' ],
	 'last_save_time' => [ 'status', 'GAUGE', 's' ],
	 'bgsave_in_progress' => [ 'status', 'BOOLEAN', '' ],
	 'vm_enabled' => [ 'status', 'BOOLEAN', '' ],
	 'uptime_in_seconds' => [ 'status', 'COUNTER', 'c' ],
	 'total_connections_received' => [ 'status', 'COUNTER', 'c', 'Total Connections Received' ],
	 'used_memory_rss' => [ 'status', 'GAUGE', 'B', 'Resident Set Size, Used Memory in Bytes' ],  	# RSS - Resident Set Size
	 'used_cpu_sys' => [ 'status', 'GAUGE', '', 'Main Process Used System CPU' ],
	 'redis_git_dirty' => [ 'status', 'BOOLEAN', '', 'Git Dirty Set Bit' ],
	 'loading' => [ 'status', 'BOOLEAN', '' ],
	 'latest_fork_usec' => [ 'status', 'GAUGE', '' ],
	 'connected_clients' => [ 'status', 'GAUGE', '', 'Total Number of Connected Clients' ],
	 'used_memory_peak_human' => [ 'status', 'GAUGE', '' ],
	 'mem_allocator' => [ 'status', 'TEXTINFO', '' ],
	 'uptime_in_days' => [ 'status', 'COUNTER', 'c', 'Total Uptime in Days' ],
	 'keyspace_hits' => [ 'status', 'COUNTER', 'c', 'Total Keyspace Hits' ],
	 'client_biggest_input_buf' => [ 'status', 'GAUGE', '' ],
	 'gcc_version' => [ 'status', 'TEXTINFO', '' ],
	 'changes_since_last_save' => [ 'status', 'COUNTER', 'c' ],
	 'arch_bits' => [ 'status', 'TEXTINFO', '' ],
	 'lru_clock' => [ 'status', 'GAUGE', '' ], 	# LRU is page replacement algorithm (least recently used), I'm unsure what this represents though
	 'role' => [ 'status', 'SETTING', '' ],
	 'multiplexing_api' => [ 'status', 'SETTING' , '' ],
	 'slave' => [ 'status', 'TEXTDATA', '' ],
	 'pubsub_channels' => [ 'status', 'GAUGE', '', 'Number of Pubsub Channels' ],
	 'redis_git_sha1' => [ 'status', 'TEXTDATA', '' ],
	 'used_cpu_user_children' => [ 'status', 'GAUGE', '', 'Child Processes Used User CPU' ],
	 'process_id' => [ 'status', 'GAUGE', '' ],
	 'used_memory_human' => [ 'status', 'GAUGE', '' ],
	 'keyspace_misses' => [ 'status', 'COUNTER', 'c', 'Keyspace Misses' ],
	 'used_cpu_user' => [ 'status', 'GAUGE', '', 'Main Process Used User CPU' ],
	 'total_commands_processed' => [ 'status', 'COUNTER', 'c', 'Total Number of Commands Processed from Start' ],
	 'mem_fragmentation_ratio' => [ 'status', 'GAUGE', '', 'Memory Fragmentation Ratio' ],
	 'client_longest_output_list' => [ 'status', 'GAUGE', '' ],
	 'blocked_clients' => [ 'status', 'GAUGE', '', 'Number of Currently Blocked Clients' ],
	 'aof_enabled' => [ 'status', 'BOOLEAN', '' ],
	 'evicted_keys' => [ 'status', 'COUNTER', 'c', 'Total Number of Evicted Keys' ],
	 'bgrewriteaof_in_progress' => [ 'status','BOOLEAN', '' ],
	 'expired_keys' => [ 'status', 'COUNTER', 'c', 'Total Number of Expired Keys' ],
	 'used_memory_peak' => [ 'status', 'GAUGE', 'B' ],
	 'connected_slaves' => [ 'status', 'GAUGE', '', 'Number of Connected Slaves' ],
	 'used_cpu_sys_children' => [ 'status', 'GAUGE', '', 'Child Processed Used System CPU' ],
	 'master_host' => [ 'status', 'TEXTINFO', '' ],
	 'master_port' => [ 'status', 'TEXTINFO', '' ],
	 'master_link_status' => [ 'status', 'TEXTINFO', '' ],
	 'slave0' => [ 'status', 'TEXTINFO', '' ],
	 'slave1' => [ 'status', 'TEXTINFO', '' ],
	 'slave2' => [ 'status', 'TEXTINFO', '' ],
	 'slave3' => [ 'status', 'TEXTINFO', '' ],
	);

# Here you can also specify which variables should go into perf data,
# For right now it is 'GAUGE', 'COUNTER', 'DATA' (but not 'TEXTDATA'), and 'BOOLEAN'
# you may want to remove BOOLEAN if you don't want too much data
my $PERF_OK_STATUS_REGEX = 'GAUGE|COUNTER|^DATA$|BOOLEAN';

# ============= MAIN PROGRAM CODE - DO NOT MODIFY BELOW THIS LINE ==============

my $o_host=     undef;		# hostname
my $o_port=     undef;		# port
my $o_pwfile=   undef;          # password file
my $o_password= undef;		# password as parameter
my $o_database= undef;		# database name (usually a number)
my $o_help=     undef;          # help option
my $o_verb=     undef;          # verbose mode
my $o_version=  undef;          # version info option
my $o_variables=undef;          # list of variables for warn and critical
my $o_perfvars= undef;          # list of variables to include in performance data
my $o_warn=     undef;          # warning level option
my $o_crit=     undef;          # Critical level option
my $o_perf=     undef;          # Performance data option
my @o_check=	();		# General check option that maybe repeated more than once
my $o_timeout=  undef;          # Timeout to use - note that normally timeout is from nagios
my $o_timecheck=undef;          # threshold spec for connection time
my $o_memutilization=undef;     # threshold spec for memory utilization%
my $o_totalmemory=undef;	# total memory on a system
my $o_hitrate=  undef;          # threshold spec for hitrate%
my $o_repdelay=undef;           # replication delay time
my @o_querykey=();		# query this key, this option maybe repeated so its an array
my $o_prevperf= undef;		# performance data given with $SERVICEPERFDATA$ macro
my $o_prevtime= undef;		# previous time plugin was run $LASTSERVICECHECK$ macro
my $o_ratelabel=undef;		# prefix and suffix for creating rate variables
my $o_rsuffix='_rate';		# default suffix	
my $o_rprefix='';

## Additional global variables
my $redis= undef;               # DB connection object
my @query=();                   # array of queries with each entry being keyed hash of processedoption data on howto query


sub p_version { print "check_redis.pl version : $Version\n"; }

sub print_usage_line {
   print "Usage: $0 [-v [debugfilename]] -H <host> [-p <port>] [-x password | -C credentials_file] [-D <database>] [-a <statistics variables> -w <variables warning thresholds> -c <variables critical thresholds>] [-A <performance output variables>] [-T [conntime_warn,conntime_crit]] [-R [hitrate_warn,hitrate_crit]] [-m [mem_utilization_warn,mem_utilization_crit] [-M <maxmemory>[B|K|M|G]]] [-r replication_delay_time_warn,replication_delay_time_crit]  [-f] [-T <timeout>] [-V] [-P <previous performance data in quoted string>] [-q (GET|LLEN|HLEN|SLEN|ZLEN|HGET:name|HEXISTS:name|SEXISTS:name|LRANGE:(AVG|SUM|MIN|MAX):start:end|ZRANGE:(AVG|SUM|MIN|MAX):start:end),query_type,query_key_name[:data_name][,ABSENT:WARNING|CRITICAL][,WARN:threshold,CRIT:threshold]] [-o <threshold specification with name or pattern>]\n";
}

sub print_usage {
   print_usage_line();
   print "For more details on options do: $0 --help\n";
}

sub help {
   my $nlib = shift;

   print "Redis Check for Nagios version ",$Version,"\n";
   print " by William Leibzon - william(at)leibzon.org\n\n";
   print "This is redis monitoring plugin to check its stats variables, replication, response time\n";
   print "hitrate, memory utilization and other info. The plugin can also query and test key data\n";
   print "against specified thresholds. All data is available as performance output for graphing.\n\n";
   print_usage_line();
   print "\n";
   print <<EOT;
General and Server Connection Options:
 -v, --verbose[=FILENAME], --debug[=FILENAME]
   Print extra debugging information.
   If filename is specified instead of STDOUT the debug data is written to that file.
 -h, --help
   Print this detailed help screen
 -H, --hostname=ADDRESS
   Hostname or IP Address to check
 -p, --port=INTEGER
   port number (default: 6379)
 -D, --database=NAME
   optional database name (usually a number), needed for --query but otherwise not needed
 -x, --password=STRING
    Password for Redis authentication. Safer alternative is to put them in a file and use -C
 -C, --credentials=FILENAME
    Credentials file to read for Redis authentication
 -t, --timeout=NUMBER
   Allows to set timeout for execution of this plugin. This overrides nagios default.
 -V, --version
   Prints version number

Variables and Thresholds Set as List:
 -a, --variables=STRING[,STRING[,STRING...]]
   List of variables from info data to do threshold checks on.
   The default (if option is not used) is not to monitor any variable.
   The variable name should be prefixed with '&' to chec its rate of
   change over time rather than actual value.
 -w, --warn=STR[,STR[,STR[..]]]
   This option can only be used if '--variables' (or '-a') option above
   is used and number of values listed here must exactly match number
   of variables specified with '-a'. The values specify warning threshold
   for when Nagios should send WARNING alert. These values are usually
   numbers and can have the following prefix modifiers:
      > - warn if data is above this value (default for numeric values)
      < - warn if data is below this value (must be followed by number)
      = - warn if data is equal to this value (default for non-numeric values)
      ! - warn if data is not equal to this value
      ~ - do not check this data (must not be followed by number or ':')
      ^ - for numeric values this disables check that warning < critical
   Threshold values can also be specified as range in two forms:
      num1:num2  - warn if data is outside range i.e. if data<num1 or data>num2
      \@num1:num2 - warn if data is in range i.e. data>=num1 && data<=num2
 -c, --crit=STR[,STR[,STR[..]]]
   This option can only be used if '--variables' (or '-a') option above
   is used and number of values listed here must exactly match number of
   variables specified with '-a'. The values specify critical threshold
   for when Nagios should send CRITICAL alert. The format is exactly same
   as with -w option except no '^' prefix.

Performance Data Processing Options:
 -f, --perfparse
   This should only be used with '-a' and causes variable data not only as part of
   main status line but also as perfparse compatible output (for graphing, etc).
 -A, --perfvars=[STRING[,STRING[,STRING...]]]
   This allows to list variables which values will go only into perfparse
   output (and not for threshold checking). The option by itself (emply value)
   is same as a special value '*' and specify to output all variables.
 -P, --prev_perfdata
   Previous performance data (normally put '-P \$SERVICEPERFDATA\$' in nagios
   command definition). This is used to calculate rate of change for counter
   statistics variables and for proper calculation of hitrate.
 --rate_label=[PREFIX_STRING[,SUFFIX_STRING]]
   Prefix or Suffix label used to create a new variable which has rate of change
   of another base variable. You can specify PREFIX or SUFFIX or both. Default
   if not specified is suffix '_rate' i.e. --rate_label=,_rate

Key Data Query Option (maybe repeated more than once):
 -q, --query=query_type,key[:varname][,ABSENT:OK|WARNING|CRITICAL,WARN:threshold,CRIT:threshold]
   query_type is one of:
	GET          - get one data value
	LLEN         - number of items in a list
	LRANGE:AVG:start:end - retrieve list and average results
	LRANGE:SUM:start:end - retrieve list and sum results
	LRANGE:MIN:start:end - retrieve list and return minimum
	LRANGE:MAX:start:end - retrieve list and return maximum
        HLEN  	     - returns number of items in a hash
        HGET:name    - get specific hash key 'name'
        HEXISTS:name - returns 0 or 1 depending on if specified hash key 'name' exists
        SLEN	     - returns number of items in a set
        SEXISTS:name - returns 0 or 1 depending on if set member 'name' exists
        ZLEN	     - returns number of items in a sorted set
        ZCOUNT:min:max     - counts items in sorted set with scores within the given values
        ZRANGE:AVG:min:max - retrieve sorted set members from min to max and average results
        ZRANGE:SUM:min:max - retrieve sorted set members from min to max and sum results
        ZRANGE:MIN:min:max - retrieve sorted set members from min to max list and return minimum
        ZRANGE:MAX:min:max - retrieve sorted set memers from min to max and return maximum

   Option specifies key to query and optional variable name to assign the results to after :
   (if not specified it would be same as key). If key is not available the plugin can issue
   either warning or critical alert depending on what you specified after ABSENT.
   Numeric results are calculated for ranges and can be checked with specified thresholds
   or you can do it together with standard with redis stats variables and -a option.

General Check Option (all 3 forms equivalent, can be repated more than once):
  -o <list of specifiers>, --option=<list of specifiers>, --check=<list of specifiers>
   where specifiers are separated by , and must include NAME or PATTERN:
     NAME:<string>   - Default name for this variable as you'd have specified with -v
     PATTERN:<regex> - Regular Expression that allows to match multiple data results
     WARN:threshold  - warning alert threshold
     CRIT:threshold  - critical alert threshold
       Threshold is a value (usually numeric) which may have the following prefix:
         > - warn if data is above this value (default for numeric values)
         < - warn if data is below this value (must be followed by number)
         = - warn if data is equal to this value (default for non-numeric values)
         ! - warn if data is not equal to this value
       Threshold can also be specified as a range in two forms:
         num1:num2  - warn if data is outside range i.e. if data<num1 or data>num2
         \@num1:num2 - warn if data is in range i.e. data>=num1 && data<=num2
     ABSENT:OK|WARNING|CRITICAL|UNKNOWN - Nagios alert (or lock of thereof) if data is absent
     ZERO:OK|WARNING|CRITICAL|UNKNOWN   - Nagios alert (or lock of thereof) if result is 0
     DISPLAY:YES|NO - Specifies if data should be included in nagios status line output
     PERF:YES|NO    - Output results as performance data or not (always YES if asked for rate)
     UOM:<string>   - Unit Of Measurement symbol to add to perf data - 'c','%','s','B'

Measured/Calculated Data:
 -T, --response_time=[WARN,CRIT]
   If this is used as just -T the plugin will measure and output connection
   response time in seconds. With -f this would also be provided on perf variables.
   You can also specify values for this parameter, these are interprted as
   WARNING and CRITICAL thresholds (separated by ',').
 -R, --hitrate=[WARN,CRIT]
   Calculates Hitrate %: cache_miss/(cache_hits+cache_miss). If this is used
   as just -R then this info just goes to output line. With '-R -f' these
   go as performance data. You can also specify values for this parameter,
   these are interprted as WARNING and CRITICAL thresholds (separated by ',').
   The format for WARN and CRIT is same as what you would use in -w and -c.
 -m, --memory_utilization=[WARN,CRIT]
   This calculates percent of total memory on system used by redis, which is
      utilization=redis_memory_rss/total_memory*100.
   Total_memory on server must be specified with -M since Redis does not report
   it and can use maximum memory unless you enabled virtual memory and set a limit
   (I plan to test this case and see if it gets reported then).
   If you specify -m by itself, the plugin will just output this info,
   with '-f' it will also include this in performance data. You can also specify
   parameter values which are interpreted as WARNING and CRITICAL thresholds.
 -M, --total_memory=NUM[B|K|M|G]
   Amount of memory on a system for memory utilization calculations above.
   If it does not end with K,M,G then its assumed to be B (bytes)
 -r, --replication_delay=WARN,CRIT
   Allows to set threshold on replication delay info. Only valid if this is a slave!
   The threshold value is in seconds and fractions are acceptable.

EOT

    if (defined($nlib) && $nlib->{'enable_long_options'} == 1) {
	my $long_opt_help = $nlib->additional_options_help();
        if ($long_opt_help) {
	    print "Stats Variable Options (this is alternative to specifying them as list with -a):\n";
	    print $long_opt_help;
	    print "\n";
        }
    }
}

############################ START OF THE LIBRARY FUNCTIONS #####################################
#
# THIS IS WORK IN PROGRESS, THE LIBRARY HAS NOT BEEN RELEASED YET AND INTERFACES MAY CHANGE
#
# ====================================== SUMMARY ================================================
#
# Name    : Naglio Perl Library For Developing Nagios Plugins
# Version : 0.2
# Date    : Aug 28, 2012
# Author  : William Leibzon - william@leibzon.org
# Licence : LGPL - full text at http://www.fsf.org/licenses/lgpl.txt
#
# ============================= LIBRARY HISTORY AND VERSIONS ====================================
#
# Note: you may safely skip this section if you're looking at documentation about this library or plugin
#
# [2006-2008]  The history of this library goes back to plugins such as check_snmp_temperature.pl,
#	       check_mysqld,pl and others released as early as 2006 with common functions to
#	       support prefixes "<,>,=,!" for specifying thresholds and checking data against
#	       these thresholds. Several of my plugins had common architecture supporting multiple
#	       variables or attributes to be checked using -a/--attributes/--variables option and
#	       --warn and --crit options with list of thresholds for these attributes and --perfvars
#	       specifying variables whose data would only go as PERFOUT for graphing.
#
# [2008-2011]  Threshold parsing and check code had been rewritten and support added for specifying
#	       range per plugin guidelines: http://nagiosplug.sourceforge.net/developer-guidelines.html
#	       Internal structures had been changing and becoming more complex to various cases.
#	       In 2010-2012 plugins started to get support for ;warn;crit output of thresholds in perf,
#	       as specified in the guidelines.
#
# [Early 2012] Code from check_memcached had been used as a base for check_memcached and then
#	       check_redis plugins with some of the latest threshold code from check_netstat
#	       with more updates. Starting with check_redis the code from check_options() and
#	       from main part of plugin that was very similar across my plugins were separated
#	       into their own functions. KNOWN_STATS_VARS array was introduced as well to be
#	       able to properly add UOM symbol ('c', '%', 's', 'ms', 'B', 'KB') to perfout.
#	       check_memcached and check_redis also included support for calculating rate of
#	       variables in a similar way to how its been done in check_snmp_netint
#
# [0.1 - July 17, 2012] In 0.6 release of check_redis.pl support had been added for long options
#	       with special threshold line syntax:
#                --option=WARN:threshold,CRIT:threshold,ABSENT:OK|WARNING|CRITICAL|UNKNOWN,DISPLAY:YES|NO,PERF:YES|NO
#	       This was extension from just doing --option=WARN,CRIT to have a more universal
#	       and extendable way to specify and alike parameters for checking. check_redis 0.6
#	       also introduced support automatically adding long options with above syntax based
#	       on description in KNOWN_STATS_VARS. The functions for the library were all separated
#	       into their own section of the code. When inported to check_memcached global variables
#	       were added to that section and accessor functions written for some of them.
#	       This is considered 0.1 version of the library
#
# [0.2 - Aug 28, 2012] In August the library code in check_memcached had been re-written from
#	       just functions to object-oriented perl interface. All variables were hidden from
#	       direct access with accessor functions written. Documentation header had been added
#	       to each library function and the header for the library itself. This was major work
#	       taking over a week to do although functions and mainly sllllame as in 0.1. They are
#	       not stabilized and so library is only to be included within plugins. Support was
#	       also added for regex matching with PATTERN option spec. Also added NAME spec.
#	       License changed to LGPL from GPL for this code.
# [0.21 - Sep 3, 2012] Fix bug in handling absent data
# [0.22 - Mar 23, 2013] Fix bug in parse_threshold functon
#
# ================================== LIBRARY TODO =================================================
#
# (a) Add library function to support '--extra-opts' to read plugin options from a file
#     This is being to be compatible with http://nagiosplugins.org/extra-opts
# (b) Support regex matching and allowing multiple data for same threshold definition.
#     [DONE]
# (c) Support for expressions in places of numeric values for thresholds. The idea is to allow
#     to refer to another variable or to special macro. I know at least one person has extended
#     my check_mysqld to support using mysql variables (not same as status data) for thresholds.
#     I also previouslyhad planned such support with experimental check_snmp_attributes plugin
#     library/base. The idea was also floated around on nagios-devel list.
# (d) Support specifying variables as expressions. This is straight out of check_snmp_atributes
#     and maybe part of it can be reused for this
# (e) Add common SNMP functions into library as so many of my plugins use it#
# (f) Add more functions to make this library easier to use and stabilize its interfaces.
#     Port my plugins to this library.
# (f) Add support for functions in Nagios-Plugins perl library. While its interfaces are
#     different, I believe, it'd be possible to add "shim" code to support them too.
# (h) Write proper Perl-style documentation as well as web documentation (much of above maybe
#     moved to web documentation) and move library to separate GITHUB project. Release it.
# (i) Port this library to Python and write one or two example plugins
#
# ================================================================================================
{
package Naglio;
use fields qw();
use Text::ParseWords;

my %ERRORS = ('OK'=>0,'WARNING'=>1,'CRITICAL'=>2,'UNKNOWN'=>3,'DEPENDENT'=>4);
my $DEFAULT_PERF_OK_STATUS_REGEX = 'GAUGE|COUNTER|^DATA$|BOOLEAN';

#  @DESCRIPTION   : Library object constructor
#  @LAST CHANGED  : 08-27-12 by WL
#  @INPUT         : Hash array of named config settings. All parameters are optiona. Currently supported are:
#		       plugin_name => string               - short name of the plugin
#		       plugin_description => string        - plugin longer description
#		       plugin_authors => string 	   - list of plugin authors
#                      knownStatsVars => reference to hash - hash array defining known variables, what type they are, their description
#		       usage_function => &ref  		   - function that would display helpful text in case of error with options for this plugin
#		       verbose => 1 or "" or "filename"    - set to 1 or "" if verbose/debug or to filename to send data to (may not be called "0" or "1")
#                      output_comparison_symbols => 0 or 1 - 1 means library output in case threshold is met can use "<", ">", "="
#						             0 means output is something like "less than or equal", "more than", etc.
#		       all_variables_perf => 0 or 1        - 1 means data for all variables would go to PERF. This is what '-A *' or just -A do
#		       enable_long_options => 0 or 1       - 1 enables long options generated based on knownStatsVars. This is automatically enabled (from 0
#							     to 1) when plugin references additional_options_list() unless this is set to -1 at library init
#		       enable_rate_of_change => 0 or 1     - enables support for calculating rate of change based on previously saved data, default is 1
#		       enable_regex_match => 0 or 1	   - when set to 1 each threshold-specified var name is treated as regex and can match
#							     to multiple collected data. this can also be enabled per-variable with PATTERN spec
#  @RETURNS       : Reference representing object instance of this library
#  @PRIVACY & USE : PUBLIC, To be used when initializing the library
sub lib_init {
    my $invocant = shift;
    my $class = ref($invocant) || $invocant;
    my %other_args = @_;

    # These used to be global variables, now these are object local variables in self with accessor
    my @allVars = ();		# all variables after options processing
    my @perfVars = ();		# performance variables list [renamed from @o_perfVarsL in earlier code]
    my %thresholds=();		# hash array of thresholds for above variables, [this replaced @o_warnL and @o_critL in earlier code]
    my %dataresults= ();	# This is where data is loaded. It is a hash with variable names as keys and array array for value:
				#   $dataresults{$var}[0] - undef of value of this variable
				#   $dataresults{$var}[1] - 0 if variable not printed out to status line yet, 1 or more otherwise
			        #   $dataresults{$var}[2] - 0 if variable data not yet put into PERF output, -1 if PERF output is preset, 1 after output
			        #   $dataresults{$var}[3] - string, '' to start with, holds ready performance data output for this variable
				#   $dataresults{$var}[4] - only for regex matches. name of match var (which should be key in thresholds), otherwise undef
    my %dataVars = ();		# keys are variables from allVars and perfVars, values is array of data that matched i.e. keys in dataresults
    my @ar_warnLv = ();		# used during options processing
    my @ar_critLv = ();		# used during options processing
    my @ar_varsL=   ();         # used during options processing
    my @prev_time=  ();     	# timestamps if more then one set of previois performance data

    my $self = {  # library and nagios versions
		_NaglioLibraryVersion => 0.2,	# this library's version
		_NagiosVersion => 3, 		# assume nagios core 3.x unless known otherwise
                # library internal data structures
		_allVars => \@allVars,
		_perfVars => \@perfVars,
	        _thresholds => \%thresholds,
		_dataresults => \%dataresults,
		_datavars => \%dataVars,
		_ar_warnLv => \@ar_warnLv,
		_ar_critLv => \@ar_critLv,
		_ar_varsL => \@ar_varsL,
		_prevTime => \@prev_time,
		_prevPerf => {},		# array that is populated with previous performance data
		_checkTime => undef,		# time when data was last checked
		_statuscode => "OK",		# final status code
		_statusinfo => "",		# if there is an error, this has human info about what it is
		_statusdata => "",		# if there is no error but we want some data in status line, this var gets it
		_perfdata => "",		# this variable collects performance data line
		_saveddata => "",		# collects saved data (for next plugin re-run, not implimented yet)
		_init_args => \%other_args,
                # copy of data from plugin option variables
		o_variables => undef,		# List of variables for warn and critical checks
		o_crit => undef,		# Comma-separated list of critical thresholds for each checked variable
		o_warn => undef,		# Comma-separated list of warning thresholds for each checked variable
		o_perf => undef,		# defined or undef. perf option means all data from variables also goes as PERFDATA
		o_perfvars => undef,		# List of variables only for PERFDATA
                o_prevperf => undef, 		# previously saved performance data coming from $SERVICEPERFDATA$ macro
	        # library special input variables (similar to options)
		o_rprefix => '',		# prefix used to distinguish rate variables
		o_rsuffix => '_rate',		# suffix used to distinguish rate variables
		knownStatusVars => {},		# Special HASH ARRAY with names and description of known variables
		perfOKStatusRegex => $DEFAULT_PERF_OK_STATUS_REGEX,
		verbose => 0,			# verbose, same as debug, same as o_verb
		plugin_name => '',		# next 3 parameters are variables are currently not used
		plugin_description => '',	# but its still better if these are provided
		plugin_authors => '',		# in the future these maybe used for help & usage functions
		# library setting variables
		debug_file => "",		# instead of setting file name in verbose, can also set it here
		output_comparison_symbols => 1, # should plugin output >,<.=,! for threshold match
						# if 0, it will say it in human form, i.e. "less"
		all_variables_perf => 0,	# should we all variables go to PERF (even those not listed in o_variables and o_perfvars)
						# this is the option set to 1 when --perfvars '*' is used
		enable_long_options => 0,	# enable support for long options generated based on knownStatusVars description
		enable_rate_of_change => 1,	# enables support for calculatin rate of chane and for rate of change long options
		enable_regex_match => 0,	# 0 is not enabled, 1 means variables in o_variables and o_perfvars are considered regex to match actual data
						# a value of 2 means its enabled, but for options with PATTERN specifier (this is not configurale value)
	      };

    # bless to create an object
    bless $self, $class;

    # deal with arguments that maybe passed to library when initalizing
    if (exists($other_args{'KNOWN_STATUS_VARS'})) {
        $self->{'knownStatusVars'} = $other_args{'KNOWN_STATUS_VARS'};
    }
    $self->{'plugin_name'} = $other_args{'plugin_name'} if exists($other_args{'plugin_name'});
    $self->{'plugin_description'} = $other_args{'plugin_description'} if exists($other_args{'plugin_description'});
    $self->{'plugin_authors'} = $other_args{'plugin_authors'} if exists($other_args{'plugin_authors'});
    $self->{'usage_function'} = $other_args{'usage_gunction'} if exists($other_args{'usage_function'});
    $self->configure(%other_args);

    # return self object
    return $self;
}

# This is just an alias for object constructor lib_init function
sub new {
    return lib_init(@_);
}

#  @DESCRIPTION   : Allows to confiure some settings after initialization (all these can also be done as part of lib_init)
#  @LAST CHANGED  : 08-27-12 by WL
#  @INPUT         : Hash array of named config settings. All parameters are optiona. Currently supported are:
#		       verbose => 1 or "" or "filename"    - set to 1 or "" if verbose/debug or to filename to send data to (may not be called "0" or "1")
#                      output_comparison_symbols => 0 or 1 - 1 means library output in case threshold is met can use "<", ">", "="
#						             0 means output is something like "less than or equal", "more than", etc.
#		       all_variables_perf => 0 or 1        - 1 means data for all variables would go to PERF. This is what '-A *' or just -A do
#		       enable_long_options => 0 or 1       - 1 enables long options generated based on knownStatsVars. This is automatically enabled (from 0
#							     to 1) when plugin references additional_options_list() unless this is set to -1 at library init
#		       enable_rate_of_change => 0 or 1     - enables support for calculating rate of change based on previously saved data, default is 1
#		       enable_regex_match => 0 or 1	   - when set to 1 each threshold-specified var name is treated as regex and can match
#							     to multiple collected data. this can also be enabled per-variable with PATTERN spec
#  @RETURNS       :  nothing (future: 1 on success, 0 on error)
#  @PRIVACY & USE : PUBLIC, Must be used as an object instance function.
sub configure {
    my $self = shift;
    my %args = @_;

    if (exists($args{'verbose'}) || exists($args{'debug'})) {
        $self->{'verbose'} = 1;
        if (exists($args{'verbose'}) && $args{'verbose'}) {
	    $self->{'debug_file'} = $args{'verbose'};
        }
        if (exists($args{'debug_log_filename'})) {
	    $self->{'debug_file'} = $args{'debug_log_filename'};
        }
    }
    $self->{'all_variables_perf'} = $args{'all_variables_perf'} if exists($args{'all_variables_perf'});
    $self->{'enable_long_options'} = $args{'enable_long_options'} if exists($args{'enable_long_options'});
    $self->{'enable_rate_of_change'} = $args{'enable_rate_of_change'} if exists($args{'enable_rate_of_change'});
    $self->{'enable_regex_match'} = 1 if exists($args{'enable_regex_match'}) && $args{'enable_regex_match'}!=0;
    $self->{'output_comparison_symbols'} = $args{'output_comparison_symbols'} if exists($args{'output_comparison_symbols'});
}

#  @DESCRIPTION   : Allows functions to take be used both directly and as object referenced functions
#                   In the 2nd case they get $self as 1st argument, in 1st they don't. this just adds
#		    $self if its if its not there so their argument list is known.
#		    Functions that allow both should still check if $self is defined
#  @LAST CHANGED  : 08-20-12 by WL
#  @INPUT         : arbitrary list of arguments
#  @RETURNS       : arbitrary list of arguments with 1st being object hash or undef
#  @PRIVACY & USE : PRIVATE
sub _self_args {
    return @_ if ref($_[0]) && exists($_[0]->{'_NaglioLibraryVersion'});
    unshift @_,undef;
    return @_;
}

#  @DESCRIPTION   : Sets function to be called to display help text on using plugin in case of error
#  @LAST CHANGED  : 08-22-12 by WL
#  @INPUT         : reference to usage function
#  @RETURNS       : nothing
#  @PRIVACY & USE : PUBLIC, Must be used as an object instance function :
sub set_usage_function {
    my ($self, $usage_function) = @_;
    $self->{'usage_function'} = $usage_function;
}

#  @DESCRIPTION   : Usage function. For right now it just calls usage function given as a parameter
#		    In the future if it is not available, it'll print something standard.
#  @LAST CHANGED  : 08-22-12 by WL
#  @INPUT         : none
#  @RETURNS       : nothing
#  @PRIVACY & USE : PUBLIC, But primary for internal use. Must be used as an object instance function.
sub usage {
  my $self = shift;
  if (defined($self) && defined($self->{'usage_function'})) { &{$self->{'usage_function'}}(); }
}

#  @DESCRIPTION   : This function converts uptime in seconds to nice & short output format
#  @LAST_CHANGED  : 08-20-12 by WL
#  @INPUT         : ARG1 - uptime in seconds
#  @RETURNS       : string of uptime for human consumption
#  @PRIVACY & USE : PUBLIC, Maybe used directly or as object instance function :
sub uptime_info {
  my ($self,$uptime_seconds) = _self_args(@_);
  my $upinfo = "";
  my ($secs,$mins,$hrs,$days) = (undef,undef,undef,undef);

  sub div_mod { return int( $_[0]/$_[1]) , ($_[0] % $_[1]); }

  ($mins,$secs) = div_mod($uptime_seconds,60);
  ($hrs,$mins) = div_mod($mins,60);
  ($days,$hrs) = div_mod($hrs,24);
  $upinfo .= "$days days" if $days>0;
  $upinfo .= (($upinfo ne '')?' ':'').$hrs." hours" if $hrs>0;
  $upinfo .= (($upinfo ne '')?' ':'').$mins." minutes" if $mins>0 && ($days==0 || $hrs==0);
  $upinfo .= (($upinfo ne '')?' ':'').$secs." seconds" if $secs>0 && $days==0 && $hrs==0;
  return $upinfo;
}

#  @DESCRIPTION   : If debug / verbose option is set, function prints its input out or to debug file
#  @LAST_CHANGED  : 08-20-12 by WL
#  @INPUT         : ARG1 - string of debug text
#  @RETURNS       : nothing
#  @PRIVACY & USE : PUBLIC, Maybe used directly or as object instance function
sub verb {
    my ($self,$in) = _self_args(@_);
    my $debug_file_name = "";

    if (defined($o_verb) || (defined($self) && defined($self->{'verbose'}) && $self->{'verbose'} ne 0)) {
        $debug_file_name = $self->{'debug_file'} if defined($self) && $self->{'debug_file'} ne "";
        $debug_file_name = $self->{'verbose'} if $debug_file_name ne "" && defined($self) &&
					         ($self->{'verbose'} ne 0 && $self->{'verbose'} ne 1 && $self->{'verbose'} ne '');
        $debug_file_name = $o_verb if $debug_file_name ne "" && defined($o_verb) && $o_verb ne "";
        if ($debug_file_name ne "") {
	    if (!open (DEBUGFILE, ">>$debug_file_name")) {
		print $in, "\n";
	    }
	    else {
		print DEBUGFILE $in,"\n";
		close DEBUGFILE;
	    }
        }
        else {
	    print $in, "\n";
        }
    }
}

#  @DESCRIPTION   : Check of string is a a number supporting integers, negative, decimal floats
#  @LAST CHANGED  : 08-20-12 by WL
#  @INPUT         : ARG1 - string of text to be checked
#  @RETURNS       : 1 if its a number, 0 if its not a number
#  @PRIVACY & USE : PUBLIC, To be used statically and not as an object instance reference
sub isnum {
    my $num = shift;
    if (defined($num) && $num =~ /^[-|+]?((\d+\.?\d*)|(^\.\d+))$/ ) { return 1 ;}
    return 0;
}

#  @DESCRIPTION   : Check of string is a a number supporting integers, negative, decimal floats
#  @LAST CHANGED  : 08-20-12 by WL
#  @INPUT         : ARG1 - string of text to be checked
#  @RETURNS       : 1 if its a number, 0 if its not a number
#  @PRIVACY & USE : PUBLIC, To be used statically and not as an object instance function
sub trim {
    my $string = shift;
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    return $string;
}

#  @DESCRIPTION   : Takes as input string from PERF or SAVED data from previous plugin invocation
#                   which should contain space-separated list of var=data pairs. The string is
#                   parsed and it returns back hash array of var=>data pairs.
#		      - Function written in 2007 for check_snmp_netint, first release 06/01/07
# 		      - Modified to use quotewords as suggested by Nicholas Scott, release of 05/20/12
#  @LAST CHANGED  : 08-27-12 by WL
#  @INPUT         : ARG1 - string of text passed from SERVICEPERFDATA OR SERVICESAVEDDATA MACRO
#  @RETURNS       : hash array (see description)
#  @PRIVACY & USE : PUBLIC, Maybe used directly or as object instance function
# TODO: double-check this works when there are no single quotes as check_snmp_netint always did quotes
sub process_perf {
   my ($self,$in) = _self_args(@_);
   my %pdh;
   my ($nm,$dt);
   use Text::ParseWords;
   foreach (quotewords('\s+',1,$in)) {
       if (/(.*)=(.*)/) {
           ($nm,$dt)=($1,$2);
	   if (defined($self)) { $self->verb("prev_perf: $nm = $dt"); }
	   else { verb("prev_perf: $nm = $dt"); }
           # in some of my plugins time_ is to profile execution time for part of plugin
           # $pdh{$nm}=$dt if $nm !~ /^time_/;
           $pdh{$nm}=$dt;
           $pdh{$nm}=$1 if $dt =~ /(\d+)[csB%]/; # 'c' or 's' or B or % maybe have been added
	   # support for more than one set of previously cached performance data
           # push @prev_time,$1 if $nm =~ /.*\.(\d+)/ && (!defined($prev_time[0]) || $prev_time[0] ne $1);
       }
   }
   return %pdh;
}

#  @DESCRIPTION   : Converts variables with white-spaces with per-name enclosed with ''
#  @LAST CHANGED  : 08-24-12 by WL
#  @INPUT         : ARG1 - varible name
#  @RETURNS       : name for perf-out output
#  @PRIVACY & USE : PUBLIC, but its use should be limited. To be used statically and not as an object instance function
sub perf_name {
    my $in = shift;
    my $out = $in;
    $out =~ s/'\/\(\)/_/g; #' get rid of special characters in performance description name
    if ($in !~ /\s/ && $in eq $out) {
        return $in;
    }
    return "'".$out."'";
}

#  @DESCRIPTION   : Determines appropriate output name (for STATUS and PERF) taking into account
#		    rate variales prefix/suffix and 'NAME' override in long thresholds line specification
#  @LAST CHANGED  : 08-26-12 by WL
#  @INPUT         : ARG1 - variable name (variable as found in dataresults)
#  @RETURNS       : name for output
#  @PRIVACY & USE : PUBLIC, but its use should be limited. To be as an object instance function,
sub out_name {
    my ($self,$dname) = @_;
    my $thresholds = $self->{'_thresholds'};
    my $dataresults = $self-> {'_dataresults'};
    my $vr = $self->data2varname($dname,1);
    my $name_out;

    if (defined($vr) && exists($thresholds->{$vr}{'NAME'})) {
	if (exists($thresholds->{$vr}{'PATTERN'}) || $self->{'enable_regex_match'} == 1) {
	    $thresholds->{$vr}{'NAMES_INDEX'} = {} if !exists($thresholds->{$vr}{'NAMES_INDEX'});
	    if (!exists($thresholds->{$vr}{'NAMES_INDEX'}{$dname})) {
		my $ncount = scalar(keys %{$thresholds->{$vr}{'NAMES_INDEX'}});
		$ncount++;
		$thresholds->{$vr}{'NAMES_INDEX'}{$dname} = $ncount;
	    }
	    $name_out = $thresholds->{$vr}{'NAME'} .'_'. $thresholds->{$vr}{'NAMES_INDEX'}{$dname};
	}
	else {
	    $name_out = $thresholds->{$vr}{'NAME'};
	}
    }
    else {
	# this is for output of rate variables which name internally start with &
	if ($dname =~ /^&(.*)/) {
	    $name_out = $self->{'o_rprefix'}.$1.$self->{'o_rsuffix'};
	}
	else {
	    $name_out = $dname;
	}
    }
    return $name_out;
}

#  @DESCRIPTION   : Builds statusline. Adds info on error conditions that would preceed status data.
#  @LAST CHANGED  : 08-20-12 by WL
#  @INPUT         : ARG1 - variable name
#		    ARG2 - string argument for status info
#  @RETURNS       : nothing (future: 1 on success, 0 on error)
#  @PRIVACY & USE : PUBLIC, but its direct use is discouraged. Must be used as an object instance function
sub addto_statusinfo_output {
    my ($self, $var, $sline) = @_;
    $self->{'_statusinfo'} .= ", " if $self->{'_statusinfo'};
    $self->{'_statusinfo'} .= trim($sline);
    $self->{'_dataresults'}{$var}[1]++;
}

#  @DESCRIPTION   : Accessor function for statusinfo
#  @LAST CHANGED  : 08-22-12 by WL
#  @INPUT         : none
#  @RETURNS       : statusinfo (error conditions and messages) string
#  @PRIVACY & USE : PUBLIC. Must be used as an object instance function
sub statusinfo {
    my $self = shift;
    if (defined($self) && defined($self->{'_statusinfo'})) {
	return $self->{'_statusinfo'};
    }
    return undef;
}

#  @DESCRIPTION   : Builds Statuline. Adds variable data for status line output in non-error condition.
#  @LAST CHANGED  : 08-26-12 by WL
#  @INPUT         : ARG1 - variable name
#		    ARG2 - formatted for human consumption text of collected data for this variable
#  @RETURNS       : nothing (future: 1 on success, 0 on error)
#  @PRIVACY & USE : PUBLIC, but its direct use is discouraged. Must be used as an object instance function
sub addto_statusdata_output {
    my ($self,$dvar,$data) = @_;
    my $thresholds = $self->{'_thresholds'};
    my $dataresults = $self -> {'_dataresults'};
    my $avar = $self->data2varname($dvar,1);

    # $self->verb("debug: addto_statusdata_output - dvar is $dvar and avar is $avar");
    if ((!exists($thresholds->{$avar}{'DISPLAY'}) || $thresholds->{$avar}{'DISPLAY'} eq 'YES') &&
        (!exists($dataresults->{$dvar}[1]) || $dataresults->{$dvar}[1] == 0)) {
           $self->{'_statusdata'} .= ", " if $self->{'_statusdata'};
           if (defined($data)) {
              $self->{'_statusdata'} .= trim($data);
           }
           elsif (exists($dataresults->{$dvar}[0])) {
              $self->{'_statusdata'} .= $self->out_name($dvar) ." is ".$dataresults->{$dvar}[0];
           }
           $dataresults->{$dvar}[1]++;
    }
}

#  @DESCRIPTION   : Accessor function for statusdata
#  @LAST CHANGED  : 08-22-12 by WL
#  @INPUT         : none
#  @RETURNS       : statusdata string (non-error data from some variables)
#  @PRIVACY & USE : PUBLIC. Must be used as an object instance function
sub statusdata {
    my $self = shift;
    if (defined($self) && defined($self->{'_statusdata'})) {
	return $self->{'_statusdata'};
    }
    return undef;
}

#  @DESCRIPTION   : This function sets text or data for data variable PERFORMANCE output
#		    (;warn;crit would be added to it later if thresholds were set for this variable)
#  @LAST CHANGED  : 08-26-12 by WL
#  @INPUT         : ARG1 - variable name
#		    ARG2 - either "var=data" text or just "data" (in which case var= is prepended to it)
#		    ARG3 - UOM symol ('c' for continous, '%' for percent, 's' for seconds) to added after data
#			   if undef then it is looked up in known variables and if one is present there, its used
#		    ARG4 - one of: "REPLACE" - if existing preset perfdata is present, it would be replaced with ARG2
#		                   "ADD"     - if existing preset perfdata is there, ARG2 string would be added to it (DEFAULT)
#				   "IFNOTSET - only set perfdata to ARG2 if it is empty, otherwise keep existing
#  @RETURNS       : nothing (future: 0 on success, -1 on error)
#  @PRIVACY & USE : PUBLIC, but its use should be limited to custom variables added by plugins to data
#                   Must be used as an object instance function
sub set_perfdata {
    my ($self,$avar,$adata,$unit,$opt) = @_;
    my $dataresults = $self->{'_dataresults'};
    my $thresholds = $self->{'_thresholds'};
    my $known_vars = $self->{'knownStatusVars'};
    my $bdata = $adata;
    my $vr = undef;

    # default operation is ADD
    if (!defined($opt)) {
	$opt = "ADD";
    }
    else {
	$opt = uc $opt;
    }
    if (defined($adata)) {
	# if only data wthout "var=" create proper perf line
	$bdata = perf_name($self->out_name($avar)).'='.$adata if $adata !~ /=/;
	if (defined($unit)) {
	    $bdata .= $unit;
	}
	else {
	    # appending UOM is done here
	    $vr = $self->data2varname($avar,1);
	    if (defined($vr)) {
		if (exists($thresholds->{$vr}{'UOM'})) {
		    $bdata .= $thresholds->{$vr}{'UOM'};
		}
	        elsif (exists($known_vars->{$vr}[2])) {
		     $bdata .= $known_vars->{$vr}[2];
		}
	    }
	}
	# preset perfdata in dataresults array
	$dataresults->{$avar}=[undef,0,0,''] if !defined($dataresults->{$avar});
	$dataresults->{$avar}[2]=-1;
	if ($opt eq "REPLACE" || !exists($dataresults->{$avar}[3]) || $dataresults->{$avar}[3] eq '') {
	    $dataresults->{$avar}[3]=$bdata;
	}
	elsif (exists($dataresults->{$avar}[3]) && $dataresults->{$avar}[3] ne '' && $opt eq "ADD") {
	    $dataresults->{$avar}[3].=$adata;
	}
    }
}

#  @DESCRIPTION   : This function is used when building performance output
#  @LAST CHANGED  : 08-26-12 by WL
#  @INPUT         : ARG1 - variable name
#		    ARG2 - optional data argument, if not present variable's dataresults are used
#		    ARG3 - one of: "REPLACE" - if existing preset perfdata is present, it would be replaced with ARG2
#		                   "ADD"    - if existing preset perfdata is there, ARG2 string would be added to it
#				   "IFNOTSET - only set perfdata to ARG2 if it is empty, otherwise keep existing (DEFAULT)
#  @RETURNS       : nothing (future: 1 on success, 0 on error)
#  @PRIVACY & USE : PUBLIC, but its direct use is discouraged. Must be used as an object instance function
sub addto_perfdata_output {
    my ($self,$avar,$adata, $opt) = @_;
    my $thresholds = $self->{'_thresholds'};
    my $dataresults = $self-> {'_dataresults'};
    my $vr = undef;

    if (!defined($opt)) {
	$opt = "IFNOTSET";
    }
    else {
	$opt = uc $opt;
    }
    $vr = $self->data2varname($avar,1);
    if (defined($avar) && defined($vr) &&
        (!exists($thresholds->{$vr}{'PERF'}) || $thresholds->{$vr}{'PERF'} eq 'YES') &&
        (!defined($dataresults->{$avar}[2]) || $dataresults->{$avar}[2] < 1)) {
           my $bdata = '';
	   if (defined($adata)) {
              $bdata .= trim($adata);
           }
	   # this is how most perfdata gets added
           elsif (defined($dataresults->{$avar}[0])) {
	      $bdata .= perf_name($self->out_name($avar)) .'='. $dataresults->{$avar}[0];
           }
	   # this would use existing preset data now if it was present due to default
	   # setting UOM from KNOWN_STATUS_VARS array is now in set_perfdata if 3rd arg is undef
	   $self->set_perfdata($avar,$bdata,undef,$opt);
	   # now we actually add to perfdata from [3] of dataresults
	   if (exists($dataresults->{$avar}[3]) && $dataresults->{$avar}[3] ne '') {
		$bdata = trim($dataresults->{$avar}[3]);
		$self->{'_perfdata'} .= " " if $self->{'_perfdata'};
		$self->{'_perfdata'} .= $bdata;
		$dataresults->{$avar}[2]=0 if $dataresults->{$avar}[2] < 0;
		$dataresults->{$avar}[2]++;
	   }
    }
}

#  @DESCRIPTION   : Accessor function for map from data collected to variable names specified in options and thresholds
#  @LAST CHANGED  : 08-22-13 by WL
#  @INPUT         : ARG1 - data variable name
#		    ARG2 - if undef or 0 return undef if no match for ARG1 found, if 1 return ARG1
#  @RETURNS       : string of variable name as was specified with --variables or --thresholds
#  @PRIVACY & USE : PUBLIC. Must be used as an object instance function
sub data2varname {
    my ($self,$dname,$ropt) = @_;
    my $dataresults = $self->{'_dataresults'};

    return $dataresults->{$dname}[4] if defined($self) && defined($dataresults->{$dname}[4]);
    return $dname if defined($ropt) && $ropt eq 1;
    return undef;
}

#  @DESCRIPTION   : Sets list and info on known variables and regex for acceptable data types.
#		    This function maybe called more than once. If called again, new vars in subsequent
#		    calls are added to existing ones and existing vars are replaced if they are there again.
#  @LAST CHANGED  : 08-22-12 by WL
#  @INPUT         : ARG1 - ref to hash array of known vars. Keys are variable names. Data is an array. Example is:
#  	 			'version' =>  [ 'misc', 'VERSION', '' ],
#			        'utilization' => [ 'misc', 'GAUGE', '%' ],
#	 			'cmd_get' => [ 'misc', 'COUNTER', 'c', "Total Number of Get Commands from Start" ],
#			   The array elements are:
#			    1st - string of source for this variable. not used by the library at all, but maybe used by code getting the data
#			    2nd - type of data in a variable. May be "GAUGE", "VERSION", "COUNTER", "BOOLEAN", "TEXTINFO", "TEXTDATA", "SETTING"
#			    3rd - either empty or one-character UOM to be added to perforance data - 'c' for continous, '%' percent, 's' seconds
#			    4th - either empty or a description of this variable. If not empty, the variable becomes long-option and this is help text
#		    ARG2 - regex of acceptable types of data for performance output. Anything else is ignored (i.e. no no output to perf), but
#			   is still available for threshold checks. if this is undef, then default of 'GAUGE|COUNTER|^DATA$|BOOLEAN' is used
#  @RETURNS       : nothing (future: 1 on success, 0 on error)
#  @PRIVACY & USE : PUBLIC, Must be used as object instance function
sub set_knownvars {
  my ($self, $known_vars_in, $vartypes_regex_in) = @_;
  my $known_vars = $self->{'knownStatusVars'};

  if (defined($known_vars_in)) {
    foreach (keys %{$known_vars_in}) {
      $known_vars->{$_} = $known_vars_in->{$_};
    }
  }
  if (defined($vartypes_regex_in)) {
      $self->{'perfOKStatusRegex'} = $vartypes_regex_in;
  }
  else {
      $self->{'perfOKStatusRegex'} = $DEFAULT_PERF_OK_STATUS_REGEX;
  }
}

#  @DESCRIPTION   : Adds known variables definition one at a time
#  @LAST CHANGED  : 08-22-12 by WL
#  @INPUT         : ARG1 - variable name
#	            ARG2 - string of source for this variable. not used by the library at all, but maybe used by code getting the data
#	            ARG3 - type of data in a variable. May be "GAUGE", "VERSION", "COUNTER", "BOOLEAN", "TEXTINFO", "TEXTDATA", "SETTING"
#	            ARG4 - either empty or one-character UOM symbol to be added to perforance data - 'c' for continous, '%' percent, 's' seconds
#		    ARG5 - either empty or a description of this variable. If not empty, the variable becomes long-option and this is help text
#  @RETURNS       : nothing (future: 1 on success, 0 on error)
#  @PRIVACY & USE : PUBLIC, Must be used as object instance function
sub add_knownvar {
  my ($self, $varname, $source, $type, $unit, $description) = @_;
  my $temp = { $varname => [ $source, $type, $unit, $description] };
  $self->set_knownvars($temp,undef);
}

#  @DESCRIPTION   : This function is used for checking data values against critical and warning thresholds
#  @LAST CHANGED  : 08-20-12 by WL
#  @INPUT         : ARG1 - variable name (used for text output in case it falls within threshold)
#		    ARG2 - data to be checked
#                   ARG3 - threshold to be checked, internal structure returned by parse_threshold()
#  @RETURNS       : Returns "" (empty string) if data is not within threshold range
#                   and text message for status line out about how data is within range otherwise
#  @PRIVACY & USE : PUBLIC. Maybe used directly or as an object instance function
sub check_threshold {
    my ($self,$attrib,$data,$th_array) = _self_args(@_);
    my $mod = $th_array->[0];
    my $lv1 = $th_array->[1];
    my $lv2 = $th_array->[2];
    my $issymb = 1;
    $issymb = 0 if defined($self) && $self->{'output_comparison_symbols'} eq 0;

    # verb("debug check_threshold: $mod : ".(defined($lv1)?$lv1:'')." : ".(defined($lv2)?$lv2:''));
    return "" if !defined($lv1) || ($mod eq '' && $lv1 eq '');
    return " " . $attrib . " is " . $data . ( ($issymb==1)?' = ':' equal to ' ). $lv1 if $mod eq '=' && $data eq $lv1;
    return " " . $attrib . " is " . $data . ( ($issymb==1)?' != ':' not equal to ' ). $lv1 if $mod eq '!' && $data ne $lv1;
    return " " . $attrib . " is " . $data . ( ($issymb==1)?' > ':' more than ' ) . $lv1 if $mod eq '>' && $data>$lv1;
    return " " . $attrib . " is " . $data . ( ($issymb==1)?' > ':' more than ' ) . $lv2 if $mod eq ':' && $data>$lv2;
    return " " . $attrib . " is " . $data . ( ($issymb==1)?' >= ':' more than or equal to ' ) . $lv1 if $mod eq '>=' && $data>=$lv1;
    return " " . $attrib . " is " . $data . ( ($issymb==1)?' < ':' less than ' ). $lv1 if ($mod eq '<' || $mod eq ':') && $data<$lv1;
    return " " . $attrib . " is " . $data . ( ($issymb==1)?' <= ':' less than or equal to ' ) . $lv1 if $mod eq '<=' && $data<=$lv1;
    return " " . $attrib . " is " . $data . " in range $lv1..$lv2" if $mod eq '@' && $data>=$lv1 && $data<=$lv2;
    return "";
}

#  @DESCRIPTION   : This function is called to parse threshold string
#  @LAST CHANGED  : 03-23-13 by WL
#		    (the code in this function can be traced back to late 2006. It has not much changed from 2008)
#  @INPUT         : ARG1 - String for one variable WARN or CRIT threshold which can be as follows:
#			 data  - warn if data is above this value if numeric data, or equal for non-numeric
#        		 >data - warn if data is above this value (default for numeric values)
#        		 <data - warn if data is below this value (must be followed by number)
#        		 =data - warn if data is equal to this value (default for non-numeric values)
#                        !data - warn if data is not equal to this value
#      		    Threshold can also be specified as range in two forms:
#        		 num1:num2  - warn if data is outside range i.e. if data<num1 or data>num2
#                       \@num1:num2 - warn if data is in range i.e. data>=num1 && data<=num2
#  @RETURNS       : Returns reference to a hash array, this library's structure for holding processed threshold spec
#  @PRIVACY & USE : PUBLIC. Maybe used directly or as an object instance function
sub parse_threshold {
    my ($self,$thin) = _self_args(@_);

    # link to an array that holds processed threshold data
    # array: 1st is type of check, 2nd is threshold value or value1 in range, 3rd is value2 in range,
    #        4th is extra options such as ^, 5th is nagios spec string representation for perf out
    my $th_array = [ '', undef, undef, '', '' ];
    my $th = $thin;
    my $at = '';

    $at = $1 if $th =~ s/^(\^?[@|>|<|=|!]?~?)//; # check mostly for my own threshold format
    $th_array->[3]='^' if $at =~ s/\^//; # deal with ^ option
    $at =~ s/~//; # ignore ~ if it was entered
    if ($th =~ /^\:([-|+]?\d+\.?\d*)/) { # :number format per nagios spec
	$th_array->[1]=$1;
	$th_array->[0]=($at !~ /@/)?'>':'<=';
	$th_array->[5]=($at !~ /@/)?('~:'.$th_array->[1]):($th_array->[1].':');
    }
    elsif ($th =~ /([-|+]?\d+\.?\d*)\:$/) { # number: format per nagios spec
        $th_array->[1]=$1;
	$th_array->[0]=($at !~ /@/)?'<':'>=';
	$th_array->[5]=($at !~ /@/)?'':'@';
	$th_array->[5].=$th_array->[1].':';
    }
    elsif ($th =~ /([-|+]?\d+\.?\d*)\:([-|+]?\d+\.?\d*)/) { # nagios range format
	$th_array->[1]=$1;
	$th_array->[2]=$2;
	if ($th_array->[1] > $th_array->[2]) {
                print "Incorrect format in '$thin' - in range specification first number must be smaller then 2nd\n";
                if (defined($self)) { $self->usage(); }
                exit $ERRORS{"UNKNOWN"};
	}
	$th_array->[0]=($at !~ /@/)?':':'@';
	$th_array->[5]=($at !~ /@/)?'':'@';
	$th_array->[5].=$th_array->[1].':'.$th_array->[2];
    }
    if (!defined($th_array->[1])) {			# my own format (<,>,=,!)
	$th_array->[0] = ($at eq '@')?'<=':$at;
	$th_array->[1] = $th;
	$th_array->[5] = '~:'.$th_array->[1] if ($th_array->[0] eq '>' || $th_array->[0] eq '>=');
	$th_array->[5] = $th_array->[1].':' if ($th_array->[0] eq '<' || $th_array->[0] eq '<=');
	$th_array->[5] = '@'.$th_array->[1].':'.$th_array->[1] if $th_array->[0] eq '=';
	$th_array->[5] = $th_array->[1].':'.$th_array->[1] if $th_array->[0] eq '!';
    }
    if ($th_array->[0] =~ /[>|<]/ && !isnum($th_array->[1])) {
	print "Numeric value required when '>' or '<' are used !\n";
        if (defined($self)) { $self->usage(); }
        exit $ERRORS{"UNKNOWN"};
    }
    # verb("debug parse_threshold: $th_array->[0] and $th_array->[1]");
    $th_array->[0] = '=' if !$th_array->[0] && !isnum($th_array->[1]) && $th_array->[1] ne '';
    if (!$th_array->[0] && isnum($th_array->[1])) { # this is just the number by itself, becomes 0:number check per nagios guidelines
	$th_array->[2]=$th_array->[1];
	$th_array->[1]=0;
	$th_array->[0]=':';
        $th_array->[5]=$th_array->[2];
    }
    return $th_array;
}

#  @DESCRIPTION   : this function checks that for numeric data warn threshold is within range of critical
#  @LAST CHANGED  : 08-20-12 by WL
#  @INPUT         : ARG1 - warhing threshold structure (reference to hash array)
#                   ARG2 - critical threshold structure (reference to hash array)
#  @RETURNS       : Returns 1 if warning does not fall within critical (there is an error)
#                   Returns 0 if everything is ok and warning is within critical
#  @PRIVACY & USE : PUBLIC, but its use is discouraged. Maybe used directly or as an object instance function.
sub threshold_specok {
    my ($self, $warn_thar,$crit_thar) = _self_args(@_);

    return 1 if defined($warn_thar) && defined($warn_thar->[1]) &&
		defined($crit_thar) && defined($crit_thar->[1]) &&
		isnum($warn_thar->[1]) && isnum($crit_thar->[1]) &&
                $warn_thar->[0] eq $crit_thar->[0] &&
                (!defined($warn_thar->[3]) || $warn_thar->[3] !~ /\^/) &&
		(!defined($crit_thar->[3]) || $crit_thar->[3] !~ /\^/) &&
              (($warn_thar->[1]>$crit_thar->[1] && ($warn_thar->[0] =~ />/ || $warn_thar->[0] eq '@')) ||
               ($warn_thar->[1]<$crit_thar->[1] && ($warn_thar->[0] =~ /</ || $warn_thar->[0] eq ':')) ||
               ($warn_thar->[0] eq ':' && $warn_thar->[2]>=$crit_thar->[2]) ||
               ($warn_thar->[0] eq '@' && $warn_thar->[2]<=$crit_thar->[2]));
    return 0;  # return with 0 means specs check out and are ok
}

#  @DESCRIPTION   : this compares var names from data to names given as plugin options treating them regex
#  @LAST CHANGED  : 08-26-12 by WL
#  @INPUT         : ARG1 - the name to search for
#  @RETURNS       : Keyname for what first one that matched from _thresholds
#                   Undef if nothing matched
#  @PRIVACY & USE : PUBLIC, but its direct use should be rare. Must be used as an object instance function.
sub var_pattern_match {
    my ($self, $name) = @_;
    my $thresholds = $self->{'_thresholds'};
    my $allvars = $self->{'_allVars'};
    my $is_regex_match = $self->{'enable_regex_match'};
    my $v;
    my $pattern;

    foreach $v (@{$allvars}) {
	$pattern='';
	if ($is_regex_match eq 1 && !defined($thresholds->{$v}{'PATTERN'})) {
	    $pattern=$v;
	}
	elsif ($is_regex_match ne 0 && defined($thresholds->{$v}{'PATTERN'})) {
	    $pattern = $thresholds->{$v}{'PATTERN'};
	}
	if ($pattern ne '' && $name =~ /$pattern/) {
	    $self->verb("Data name '".$name."' matches pattern '".$pattern."'");
	    return $v;
	}
    }
    return undef;
}

#  @DESCRIPTION   : This function adds data results
#  @LAST CHANGED  : 08-27-12 by WL
#  @INPUT         : ARG1 - name of data variable
#                   ARG2 - data for this variable
#		    ARG3 - name of checked variable/parameter corresponding to this data variable
#			   default undef, assumed to be same as ARG1
#  @RETURNS       : nothing (future: 1 on success, 0 on error)
#  @PRIVACY & USE : PUBLIC, Must be used as an object instance function
sub add_data {
    my ($self, $dnam, $dval, $anam) = @_;
    my $thresholds = $self->{'_thresholds'};
    my $dataresults = $self-> {'_dataresults'};
    my $datavars = $self -> {'_datavars'};
    my $perfVars = $self->{'_perfVars'};

    # determine what plugin options-specified var & threshold this data corresponds to
    if (!defined($anam)) {
	if ($self->{'enable_regex_match'} == 0) {
	    $anam = $dnam;
	}
	else {
	    $anam = $self->var_pattern_match($dnam);
	    $anam = $dnam if !defined($anam);
	}
    }
    # set dataresults
    if (exists($dataresults->{$dnam})) {
        $dataresults->{$dnam}[0] = $dval;
        $dataresults->{$dnam}[4] = $anam if defined($anam);
    }
    else {
        $dataresults->{$dnam} = [$dval, 0, 0, '', $anam];
    }
    # reverse map array
    $datavars->{$anam} = [] if !exists($datavars->{$anam});
    push @{$datavars->{$anam}}, $dnam;
    # setperf if all variables go to perf
    if ($self->{'all_variables_perf'} == 1) {
        $thresholds->{$anam}={} if !exists($thresholds->{$anam});
	$thresholds->{$anam}{'PERF_DATALIST'} = [] if !exists($thresholds->{$anam}{'PERF_DATALIST'});
	push @{$thresholds->{$anam}{'PERF_DATALIST'}}, $dnam;
	if (!defined($thresholds->{$anam}{'PERF'})) {
	    push @{$perfVars}, $anam;
	    $thresholds->{$anam}{'PERF'} = 'YES';
	}
    }
}

#  @DESCRIPTION   : Accessor function that gets variable data
#  @LAST CHANGED  : 08-20-12 by WL
#  @INPUT         : ARG1 - name of data variable
#  @RETURNS       : undef if variable does not exist and data otherwise
#  @PRIVACY & USE : PUBLIC, Must be used as an object instance function
sub vardata {
    my ($self,$dnam) = @_;
    my $dataresults = $self->{'_dataresults'};
    return undef if !exists($dataresults->{$dnam});
    return $dataresults->{$dnam}[0];
}

#  @DESCRIPTION   : This function parses "WARN:threshold,CRIT:threshold,ABSENT:OK|WARNING|CRITICAL|UNKNOWN" combined threshold string
#		    Parsing of actual threshold i.e. what is after WARN, CRIT is done by parse_threshold() function
#  @LAST CHANGED  : 08-27-12 by WL
#  @INPUT         : ARG1 - String containing threshold line like "WARN:threshold,CRIT:threshold,ABSENT:OK|WARNING|CRITICAL|UNKNOWN"
#		    Acceptable comma-separated parts threshold specifiers are:
#		       WARN:<threshold> - warning threshold
#		       CRIT:<treshold>  - critical threshold
#		       ABSENT:OK|WARNING|CRITICAL|UNKNOWN - nagios exit code if data for this variable is not found
#		       ZERO:OK|WARNING|CRITICAL|UNKNOWN - nagios exit code if data is 0
#		       DISPLAY:YES|NO - output data in plugin status line
#		       PERF:YES|NO    - output data as plugin performance data
#		       SAVED:YES|NO   - put results in saved data (this really should not be set manually)
#		       PATTERN:<regex> - enables regex match allowing more than one real data name to match this threshold
#		       NAME:<string> - overrides output status and perf name for this variable
#		       UOM:<string>  - unit of measurement symbol to add to perf
#  @RETURNS       : Returns reference to a hash array, a library's structure for holding processed MULTI-THRESHOLD spec
#		    Note that this is MULTI-THRESHOLD hash structure, it itself contains threshold hashes returned by parse_threshold()
#  @PRIVACY & USE : PUBLIC, but its use is discouraged. Maybe used directly or as an object instance function.
sub parse_thresholds_list {
   my ($self,$in) = _self_args(@_);
   my $thres = {};
   my @tin = undef;
   my $t = undef;
   my $t2 = undef;

   @tin = split(',', $in);
   $t = uc $tin[0] if exists($tin[0]);
   # old format with =warn,crit thresolds without specifying which one
   if (defined($t) && $t !~ /^WARN/ && $t !~ /^CRIT/ && $t !~ /^ABSENT/ && $t !~ /^ZERO/ &&
	  $t !~ /^DISPLAY/ && $t !~ /^PERF/ && $t !~ /^SAVED/ &&
          $t !~ /^PATTERN/ && $t !~ /^NAME/ && $t !~ /^UOM/) {
	if (scalar(@tin)==2) {
	     if (defined($self)) {
		  $thres->{'WARN'} = $self->parse_threshold($tin[0]);
		  $thres->{'CRIT'} = $self->parse_threshold($tin[1]);
	     }
	     else {
		  $thres->{'WARN'} = parse_threshold($tin[0]);
		  $thres->{'CRIT'} = parse_threshold($tin[1]);
	     }
	}
	else {
	     print "Can not parse. Unknown threshold specification: $in\n";
	     print "Threshold line should be either both warning and critical thresholds separated by ',' or \n";
	     print "new format of: WARN:threshold,CRIT:threshold,ABSENT:OK|WARNING|CRITICAL|UNKNOWN\n";
	     print "which allows to specify all 3 (CRIT,WARN,ABSENT) or any one of them in any order\n";
             if (defined($self)) { $self->usage(); }
             exit $ERRORS{"UNKNOWN"};
	}
   }
   # new format with prefix specifying if its WARN or CRIT and support of ABSENT
   else {
	foreach $t (@tin) {
	     $t2 = uc $t;
	     if ($t2 =~ /^WARN\:(.*)/) {
		    if (defined($self)) {
			$thres->{'WARN'} = $self->parse_threshold($1);
		    }
		    else {
			$thres->{'WARN'} = parse_threshold($1);
		    }
	     }
	     elsif ($t2 =~ /^CRIT\:(.*)/) {
		    if (defined($self)) {
			$thres->{'CRIT'} = $self->parse_threshold($1);
		    }
		    else {
			$thres->{'CRIT'} = parse_threshold($1);
		    }
	     }
	     elsif ($t2 =~ /^ABSENT\:(.*)/) {
		    my $val = $1;
		    if (defined($ERRORS{$val})) {
			$thres->{'ABSENT'} = $val;
		    }
		    else {
			print "Invalid value $val after ABSENT. Acceptable values are: OK, WARNING, CRITICAL, UNKNOWN\n";
			if (defined($self)) { $self->usage(); }
			exit $ERRORS{"UNKNOWN"};
		    }
	     }
	     elsif ($t2 =~ /^ZERO\:(.*)/) {
		    my $val = $1;
		    if (exists($ERRORS{$val})) {
			$thres->{'ZERO'} = $val;
		    }
		    else {
			print "Invalid value $val after ZERO. Acceptable values are: OK, WARNING, CRITICAL, UNKNOWN\n";
			if (defined($self)) { $self->usage(); }
			exit $ERRORS{"UNKNOWN"};
		    }
	     }
	     elsif ($t2 =~ /^DISPLAY\:(.*)/) {
		   if ($1 eq 'YES' || $1 eq 'NO') {
			$thres->{'DISPLAY'} = $1;
		   }
		   else {
			print "Invalid value $1 after DISPLAY. Specify this as YES or NO.\n";
			if (defined($self)) { $self->usage(); }
			exit $ERRORS{"UNKNOWN"};
		   }
	     }
	     elsif ($t2 =~ /^PERF\:(.*)/) {
                  if ($1 eq 'YES' || $1 eq 'NO') {
                        $thres->{'PERF'} = $1;
                   }
                   else {
                        print "Invalid value $1 after PERF. Specify this as YES or NO.\n";
                        if (defined($self)) { $self->usage(); }
                        exit $ERRORS{"UNKNOWN"};
                   }
             }
	     elsif ($t =~ /^PATTERN\:(.*)/i) {
		   $thres->{'PATTERN'} = $1;
		   $self->{'enable_regex_match'} = 2 if defined($self) && $self->{'enable_regex_match'} eq 0;
	     }
	     elsif ($t =~ /^NAME\:(.*)/i) {
		   $thres->{'NAME'} = $1;
	     }
	     elsif ($t =~ /^UOM\:(.*)/i) {
		   $thres->{'UOM'} = $1;
	     }
	     else {
		    print "Can not parse. Unknown threshold specification: $_\n";
		    print "Threshold line should be WARN:threshold,CRIT:threshold,ABSENT:OK|WARNING|CRITICAL|UNKNOWN,ZERO:OK|WARNING|CRITICAL|UNKNOWN\n";
		    if (defined($self)) { $self->usage(); }
		    exit $ERRORS{"UNKNOWN"};
	     }
	}
   }
   if (exists($thres->{'WARN'}) && exists($thres->{'CRIT'})) {
	  my $check_warncrit = 0;
	  if (defined($self)) {
	      $check_warncrit = $self->threshold_specok($thres->{'WARN'},$thres->{'CRIT'});
	  }
	  else {
	      $check_warncrit = threshold_specok($thres->{'WARN'},$thres->{'CRIT'});
	  }
	  if ($check_warncrit) {
                 print "All numeric warning values must be less then critical (or greater then when '<' is used)\n";
                 print "Note: to override this check prefix warning value with ^\n";
                 if (defined($self)) { $self->usage(); }
                 exit $ERRORS{"UNKNOWN"};
          }
   }
   return $thres;
}

#  @DESCRIPTION   : Adds variable to those whose thresholds would be checked
#  @LAST CHANGED  : 08-27-12 by WL
#  @INPUT         :  ARG1 - name of the data variable
#  		     ARG2 - either:
#			 1) ref to combined thresholds hash array i.e. { 'WARN' => threshold array, 'CRIT' => threshold array, ABSENT => ... }
#                           such hash array is returned by by parse_thresholds_list function
#			 -- OR --
#			 2) a tet string with a list of thresholds in the format
#			     WARN:threshold,CRIT:thresholod,ABSENT:OK|WARNING|CRITICAL|UNKNOWN,ZERO:WARNING|CRITICAL|UNKNOWN,PATTERN:pattern,NAME:name
# 			    which would get parsed y parse_thresholds_list function into ref array
#  @RETURNS       : nothing (future: 1 on success, 0 on error)
#  @PRIVACY & USE : PUBLIC, Recommend function for adding thresholds. Must be used as an object instance function
sub add_thresholds {
    my ($self,$var,$th_in) = @_;
    my $th;
    if (ref($th_in) && (exists($th_in->{'WARN'}) || exists($th_in->{'CRIT'}) || exists($th_in->{'DISPLAY'}) ||
		         exists($th_in->{'PERF'}) || exists($th_in->{'SAVED'}) || exists($th_in->{'ABSENT'}) ||
			 exists($th_in->{'ZERO'}) || exists($th_in->{'PATTERN'}))) {
	$th = $th_in;
    }
    else {
	$th = $self->parse_thresholds_list($th_in);
    }
    if (!defined($var)) {
	if (defined($th->{'NAME'})) {
	    $var = $th->{'NAME'};
	}
	elsif (defined($th->{'PATTERN'})) {
	    $var = $th->{'PATTERN'};
	}
	else {
	    print "Can not parse. No name or pattern in threshold: $th_in\n";
	    print "Specify threshold line as:  NAME:name,PATTERN:regex,WARN:threshold,CRIT:threshold,ABSENT:OK|WARNING|CRITICAL|UNKNOWN,ZERO:OK|WARNING|CRITICAL|UNKNOWN\n";
	    $self->usage();
	    exit $ERRORS{"UNKNOWN"};
	}
    }
    push @{$self->{'_allVars'}}, $var if !exists($self->{'_thresholds'}{$var});
    $self->{'_thresholds'}{$var}=$th;
}

#  @DESCRIPTION   : Accessor function for thresholds and related variable settings on what and how to check
#  @LAST CHANGED  : 08-20-12 by WL
#  @INPUT         : ARG1 - name of data variable
#                   ARG2 - name of the threshold or related data setting to return
#		           This can be: "WARN", "CRIT", "ABSENT", "ZERO", "DISPLAY", "PERF"
#  @RETURNS       : undef if variable does not exist
#  		    if variable exists and "WARN" or "CRIT" thresholds are requested, it returns asociated
#  		    threshold hash array structure for named threshold of the type returned by parse_threshold()
#                   for ABSENT, ZERO, DISPLAY, PERF and other, it returns a string for this check setting
#  @PRIVACY & USE : PUBLIC, Must be used as an object instance function
sub get_threshold {
    my ($self,$var,$thname) = @_;
    return undef if !exists($self->{'_thresholds'}{$var}) || !exists($self->{'_thresholds'}{$var}{$thname});
    return $self->{'_thresholds'}{$var}{$thname};
}

#  @DESCRIPTION   : Modifier function for thresholds and related variable settings on how to check and display results
#  @LAST CHANGED  : 08-20-12 by WL
#  @INPUT         : ARG1 - name of data variable
#                   ARG2 - type of the threshold or related data setting
#		           This can be: "WARN", "CRIT", "ABSENT", "ZERO", "DISPLAY", "PERF"
#                   ARG3 - what to set this to, for "WARN" and "CRIT" this must be hash array returned by parse_threshold()
#  @RETURNS       : 0 if type you want to set is not one of "WARN", "CRIT", "ZERO" or other acceptable settings
#  		    1 on success
#  @PRIVACY & USE : PUBLIC, Must be used as an object instance function
sub set_threshold {
    my ($self,$var,$thname,$thdata) = @_;
    if ($thname ne 'WARN' && $thname ne 'CRIT' && $thname ne 'ZERO' && $thname ne 'PATTERN' && $thname ne 'NAME' &&
        $thname ne 'ABSENT' && $thname ne 'PERF' && $thname ne 'DISPLAY' && $thname ne 'SAVED' && $thname ne 'UOM') {
       return 0;
    }
    $self->{'_thresholds'}{$var}={} if !exists($self->{'_thresholds'}{$var});
    $self->{'_thresholds'}{$var}{$thname}=$thdata;
    return 1;
}

#  @DESCRIPTION   : Returns list variables for GetOptions(..) that are long-options based on known/defined variable
#  @LAST CHANGED  : 08-20-12 by WL
#  @INPUT         : none
#  @RETURNS       : Array of additional options based on KNOWN_STATS_VARS
#  @PRIVACY & USE : PUBLIC, Special use case with GetOpt::Long. Must be used as an object instance function
sub additional_options_list {
    my $self = shift;

    my $known_vars = $self->{'knownStatusVars'};
    my ($o_rprefix, $o_rsuffix, $v, $v2) = ('','','','');
    $o_rprefix = $self->{'o_rprefix'} if defined($self->{'o_rprefix'});
    $o_rsuffix = $self->{'o_rsuffix'} if defined($self->{'o_rsuffix'});
    my @VarOptions = ();

    if ($self->{'enable_long_options'} != -1) {
      if (defined($self) && defined($known_vars)) {
	foreach $v (keys %{$known_vars}) {
	  if (exists($known_vars->{$v}[3]) && $known_vars->{$v}[3] ne '') {
              push @VarOptions,$v."=s";
	      if ($self->{'enable_rate_of_change'} eq 1 && $known_vars->{$v}[1] eq 'COUNTER' && ($o_rprefix ne '' || $o_rsuffix ne '')) {
		   $v2 = $o_rprefix.$v.$o_rsuffix;
		   push @VarOptions,$v2."=s"
	      }
	  }
	}
      }
    }
    if (scalar(@VarOptions)>0) {
      $self->{'enable_long_options'} = 1;
    }
    return @VarOptions;
}

#  @DESCRIPTION   : Prints out help for generated long options
#  @LAST CHANGED  : 08-20-12 by WL
#  @INPUT         : none
#  @RETURNS       : a string of text for help output
#  @PRIVACY & USE : PUBLIC, Special use case with GetOpt::Long. Must be used as an object instance function
sub additional_options_help {
  my $self = shift;
  my $vname;
  my $vname2;
  my $counter = 0;
  my $known_vars = $self->{'knownStatusVars'};

  if ($self->{'enable_long_options'} != 1) { return ''; }

  my $out="   These options are all --long_name=<list of specifiers separated by ,>
   where specifiers are one or more of:
     WARN:threshold  - warning alert threshold
     CRIT:threshold  - critical alert threshold
       Threshold is a value (usually numeric) which may have the following prefix:
         > - warn if data is above this value (default for numeric values)
         < - warn if data is below this value (must be followed by number)
         = - warn if data is equal to this value (default for non-numeric values)
         ! - warn if data is not equal to this value
       Threshold can also be specified as a range in two forms:
         num1:num2  - warn if data is outside range i.e. if data<num1 or data>num2
         \@num1:num2 - warn if data is in range i.e. data>=num1 && data<=num2
     ABSENT:OK|WARNING|CRITICAL|UNKNOWN - Nagios alert (or lock of thereof) if data is absent
     ZERO:OK|WARNING|CRITICAL|UNKNOWN   - Nagios alert (or lock of thereof) if result is 0
     DISPLAY:YES|NO - Specifies if data should be included in nagios status line output
     PERF:YES|NO    - Output results as performance data or not (always YES if asked for rate)
     NAME:<string>  - Change the name to <string> in status and PERF output\n\n";

  # add more options based on KNOWN_STATUS_VARS array
  foreach $vname (keys(%{$known_vars})) {
     if (exists($known_vars->{$vname}[3])) {
	$counter++;
	$out .= ' --'.$vname."=WARN:threshold,CRIT:threshold,<other specifiers>\n";
	$out .= "   ".$known_vars->{$vname}[3]."\n";
	if ($known_vars->{$vname}[1] eq 'COUNTER' && $self->{'enable_rate_of_change'} eq 1) {
	    $vname2=$o_rprefix.$vname.$o_rsuffix;
	    $out .= ' --'.$vname2."=WARN:threshold,CRIT:threshold,<other specifiers>\n";
	    $out .= "   Rate of Change of ".$known_vars->{$vname}[3]."\n";
	}
     }
  }
  if ($counter>0) { return $out; }
  return "";
}

#  @DESCRIPTION   : Processes standard options parsing out of them variables to be checked
#  @LAST CHANGED  : 08-20-12 by WL
#  @INPUT         : ARG1 - Options data hash from GetOpt::Long
#		    ARG2 - option --verbose or -v or --debug : undef normally and "" or filename if debug enabled
#		    ARG3 - option --variables or -a in WL's plugins : comma-separated list of variables to check
#		    ARG4 - option --warn or -w : comma-separated warning thresholds for variables in ARG3
#		    ARG5 - option --crit or -c : comma-separated critical thresholds for variables in ARG3
#		    ARG6 - option --perf or -f in WL's plugin: all regular variables should also go to perf data
#		    ARG7 - option --perfvars or -A in WL's plugins: command-separated list of variables whose data goes to PERF output
#		    ARG8 - prefix to distinguish rate variables, maybe "" but usually this is "rate_"
#		    ARG9 - suffix to distinguish rate variables, only if ARG7 is "", otherwise optional and absent
#  @RETURNS       : nothing (future: 1 on success, 0 on error)
#  @PRIVACY & USE : PUBLIC, To be used shortly after GetOptions. Must be used as an object instance function
sub options_startprocessing {
    my ($self, $Options, $o_verb, $o_variables, $o_warn, $o_crit, $o_perf, $o_perfvars, $o_rprefix, $o_rsuffix) = @_;

    # Copy input parameters to object hash array, set them if not present
    $o_rprefix="" if !defined($o_rprefix);
    $o_rsuffix="" if !defined($o_rsuffix);
    $o_crit="" if !defined($o_crit);
    $o_warn="" if !defined($o_warn);
    $o_variables="" if !defined($o_variables);
    $self->{'o_variables'} = $o_variables;
    $self->{'o_perfvars'} = $o_perfvars;
    $self->{'o_crit'} = $o_crit;
    $self->{'o_warn'} = $o_warn;
    $self->{'o_perf'} = $o_perf;
    $self->{'o_rprefix'} = $o_rprefix;
    $self->{'o_rsuffix'} = $o_rsuffix;
    $self->{'verbose'} = $o_verb if defined($o_verb);
    # start processing
    my $perfVars = $self->{'_perfVars'};
    my $ar_varsL = $self->{'_ar_varsL'};
    my $ar_critLv = $self->{'_ar_critLv'};
    my $ar_warnLv = $self->{'_ar_warnLv'};
    my $known_vars = $self->{'knownStatusVars'};
    $o_rprefix = lc $o_rprefix;
    $o_rsuffix = lc $o_rsuffix;
    # process o_perfvars option
    if (defined($o_perfvars)) {
	@{$perfVars} = split( /,/ , lc $o_perfvars );
 	if (scalar(@{$perfVars})==0) {
		$o_perfvars='*';
		$self->{'o_perfvars'}='*';
	}
	if ($o_perfvars eq '*') {
		$self->{'all_variables_perf'} = 1;
	}
	else {
		# below loop converts rate variables to internal representation
		for (my $i=0; $i<scalar(@{$perfVars}); $i++) {
			$perfVars->[$i] = '&'.$1 if $perfVars->[$i] =~ /^$o_rprefix(.*)$o_rsuffix$/;
		}
	}
    }
    if (defined($o_warn) || defined($o_crit) || defined($o_variables)) {
	if (defined($o_variables)) {
	  @{$ar_varsL}=split( /,/ , lc $o_variables );
	  if (defined($o_warn)) {
	     $o_warn.="~" if $o_warn =~ /,$/;
	     @{$ar_warnLv}=split( /,/ , lc $o_warn );
	  }
	  if (defined($o_crit)) {
	     $o_crit.="~" if $o_crit =~ /,$/;
    	     @{$ar_critLv}=split( /,/ , lc $o_crit );
	  }
	}
	else {
	  print "Specifying warning or critical thresholds requires specifying list of variables to be checked\n";
	  if (defined($self)) { $self->usage(); }
	  exit $ERRORS{"UNKNOWN"};
	}
    }
    # this is a special loop to check stats-variables options such as "connected_clients=WARN:warning,CRIT:critical"
    # which are specified as long options (new extended threshold line spec introduced in check_redis and check_memcached)
    my ($vname,$vname2) = (undef,undef);
    foreach $vname (keys(%{$known_vars})) {
	$vname2=$o_rprefix.$vname.$o_rsuffix;
	if (exists($known_vars->{$vname}[3])) {
	    if (exists($Options->{$vname})) {
		 $self->verb("Option $vname found with spec parameter: ".$Options->{$vname});
		 $self->add_thresholds($vname,$Options->{$vname});
	    }
	    if (exists($Options->{$vname2})) {
		 $self->verb("Rate option $vname2 found with spec parameter: ".$Options->{$vname2});
		 $self->add_thresholds('&'.$vname,$Options->{$vname2});
	    }
	}
    }
    $self->{'_called_options_startprocessing'}=1;
}

#  @DESCRIPTION   : Internal function. Parses and sets thresholds for given list of variables after all options have been processed
#  @LAST CHANGED  : 08-20-12 by WL
#  @INPUT         : none
#  @RETURNS       : nothing (future: 1 on success, 0 on error)
#  @PRIVACY & USE : PRIVATE, Must be used as an object instance function
sub _options_setthresholds {
    my $self = shift;

    my $perfVars = $self->{'_perfVars'};
    my $ar_varsL = $self->{'_ar_varsL'};
    my $ar_critLv = $self->{'_ar_critLv'};
    my $ar_warnLv = $self->{'_ar_warnLv'};
    my $known_vars = $self->{'knownStatusVars'};
    my $thresholds = $self->{'_thresholds'};
    my ($o_rprefix, $o_rsuffix) = ("", "");
    $o_rprefix = $self->{'o_rprefix'} if exists($self->{'o_rprefix'});
    $o_rsuffix = $self->{'o_rsuffix'} if exists($self->{'o_rsuffix'});

    if (scalar(@{$ar_warnLv})!=scalar(@{$ar_varsL}) || scalar(@{$ar_critLv})!=scalar(@{$ar_varsL})) {
	  printf "Number of specified warning levels (%d) and critical levels (%d) must be equal to the number of attributes specified at '-a' (%d). If you need to ignore some attribute do it as ',,'\n", scalar(@{$ar_warnLv}), scalar(@{$ar_critLv}), scalar(@{$ar_varsL});
	  $self->verb("Warning Levels: ".join(",",@{$ar_warnLv}));
	  $self->verb("Critical Levels: ".join(",",@{$ar_critLv}));
	  if (defined($self)) { $self->usage(); }
	  exit $ERRORS{"UNKNOWN"};
    }
    for (my $i=0; $i<scalar(@{$ar_varsL}); $i++) {
	  $ar_varsL->[$i] = '&'.$1 if $ar_varsL->[$i] =~ /^$o_rprefix(.*)$o_rsuffix$/;
	  if ($ar_varsL->[$i] =~ /^&(.*)/) {
		if (!defined($self->{'o_prevperf'})) {
			print "Calculating rate variable such as ".$ar_varsL->[$i]." requires previous performance data. Please add '-P \$SERVICEPERFDATA\$' to your nagios command line.\n";
			if (defined($self)) { $self->usage(); }
			exit $ERRORS{"UNKNOWN"};
		}
		if (defined($known_vars->{$1}) && $known_vars->{$1}[0] ne 'COUNTER') {
                	print "$1 is not a COUNTER variable for which rate of change should be calculated\n";
			if (defined($self)) { $self->usage(); }
                	exit $ERRORS{"UNKNOWN"};
		}
	  }
	  if (!exists($thresholds->{$ar_varsL->[$i]})) {
	      my $warn = $self->parse_threshold($ar_warnLv->[$i]);
	      my $crit = $self->parse_threshold($ar_critLv->[$i]);
	      if ($self->threshold_specok($warn,$crit)) {
                 print "All numeric warning values must be less then critical (or greater then when '<' is used)\n";
                 print "Note: to override this check prefix warning value with ^\n";
                 if (defined($self)) { $self->usage(); }
                 exit $ERRORS{"UNKNOWN"};
	      }
	      $self->add_thresholds($ar_varsL->[$i], {'WARN'=>$warn,'CRIT'=>$crit} );
	  }
    }
}

#  @DESCRIPTION   : Internal helper function. Finds time when previous performance data was calculated/saved at
#  @DEVNOTE	  : Right now this library and function only supports one previous performance data set,
#		    but check_snmp_netint plugin supports multiple sets and there the code is more complex,
#		    As this function originated there, that code is commented out right now.
#  @LAST CHANGED  : 08-21-12 by WL
#  @INPUT         :  ARG1 - reference to previous performance data hash array. It looks for _ptime variable there.
#		     ARG2 - string with previous performance time in unix seconds. This may come from separate plugin option.
#  @RETURNS       : Time in unix seconds frm 1970 or undef if it was not located
#  @PRIVACY & USE : PRIVATE, Maybe used directly or as an object instance function.
sub _set_prevtime {
    my ($self,$prevperf,$o_prevtime) = _self_args(@_);
    my $perfcheck_time;

    if (defined($o_prevtime)) {
         # push @prev_time, $o_prevtime;
         # $prev_perf{ptime}=$o_prevtime;
	 $perfcheck_time=$o_prevtime;
    }
    elsif (defined($prevperf) && defined($prevperf->{'_ptime'})) {
	 # push @prev_time, $prev_perf{ptime};
	 $perfcheck_time=$prevperf->{'_ptime'};
    }
    else {
         # @prev_time=();
	 $perfcheck_time=undef;
    }
    # numeric sort for timestamp array (this is from lowest time to highiest, i.e. to latest)
    # my %ptimes=();
    # $ptimes{$_}=$_ foreach @prev_time;
    # @prev_time = sort { $a <=> $b } keys(%ptimes);
    return $perfcheck_time;
}

#  @DESCRIPTION   : Processes standard options, setting up thresholds based on options that are to be checked
#  @LAST CHANGED  : 08-22-12 by WL
#  @INPUT         : none
#  @RETURNS       : nothing (future: 1 on success, 0 on error)
#  @PRIVACY & USE : PUBLIC, To be called after plugin finished processing its own custom options. Must be used as an object instance function
sub options_finishprocessing {
    my $self = shift;

    if (!exists($self->{'_called_options_finishprocessing'})) {
	# process previous performance data
	my $prevperf = $self->{'_prevPerf'};
	if (defined($self->{'o_prevperf'})) {
	      if (defined($self->{'o_perf'}) || defined($self->{'o_perfvars'})) {
		    %{$prevperf}=$self->process_perf($self->{'o_prevperf'});
		    $self->{'_perfcheck_time'} = $self->_set_prevtime($prevperf,$self->{'o_prevtime'});
	      }
	      else {
		    print "--prevperf can only be used with --perf or --perfvars options\n";
		    if (defined($self)) { $self->usage(); }
		    exit $ERRORS{"UNKNOWN"};
	      }
	}
	# set thresholds
	$self->_options_setthresholds();
        # prepare data results arrays
	my $dataresults = $self->{'_dataresults'};
	my $thresholds = $self->{'_thresholds'};
	$dataresults->{$_} = [undef, 0, 0] foreach(@{$self->{'_allVars'}});
	if (defined($self->{'_perfVars'})) {
	    foreach(@{$self->{'_perfVars'}}) {
		$dataresults->{$_} = [undef, 0, 0] if !exists($dataresults->{$_});
		$thresholds->{$_} = {} if !exists($thresholds->{$_});
		$thresholds->{$_}{'PERF'} = 'YES';
	    }
	}
	# mark as having finished
	$self->{'_called_options_finishprocessing'}=1;
    }
}

#  @DESCRIPTION   : Accessor function for previously saved perfdata
#  @LAST CHANGED  : 08-22-12 by WL
#  @INPUT         : ARG1 - varname
#  @RETURNS       : value of that variable on previous plugin run, undef if not known
#  @PRIVACY & USE : PUBLIC, Must be used as an object instance function
sub prev_perf {
    my ($self,$var) = @_;
    if (defined($self) && defined($self->{'_prevPerf'}{$var})) {
        return $self->{'_prevPerf'}{$var};
    }
    return undef;
}

#  @DESCRIPTION   : Accessor function for exit status code
#  @LAST CHANGED  : 08-21-12 by WL
#  @INPUT         : none
#  @RETURNS       : current expected exit status code
#  @PRIVACY & USE : PUBLIC, Must be used as an object instance function
sub statuscode {
    my $self = shift;
    return $self->{'_statuscode'};
}

#  @DESCRIPTION   : Sets plugin exist status
#  @LAST CHANGED  : 08-21-12 by WL
#  @INPUT         : status code string - one of "WARNING", "CRITICAL", "UNKNOWN".
#  @RETURNS       : 0 on success, 1 if this status code is below level that plugin would exit with and as such it was not set
#  @PRIVACY & USE : PUBLIC, Must be used as an object instance function
sub set_statuscode {
    my ($self,$newcode) = @_;

    if ($newcode eq 'UNKNOWN') {
        $self->{'_statuscode'} = 'UNKNOWN';
        return 0;
    }
    if ($self->{'_statuscode'} eq 'UNKNOWN') { return 1; }
    elsif ($self->{'_statuscode'} eq 'CRITICAL') {
        if ($newcode eq 'CRITICAL') { return 0;}
        else { return 1; }
    }
    elsif ($self->{'_statuscode'} eq 'WARNING') {
        if ($newcode eq 'CRITICAL') {
	    $self->{'_statuscode'} ='CRITICAL';
	    return 0;
        }
        elsif ($newcode eq 'WARNING') { return 0; }
        else { return 1; }
    }
    elsif ($self->{'_statuscode'} eq 'OK') {
        if ($newcode eq 'CRITICAL' || $newcode eq 'WARNING') {
	    $self->{'_statuscode'} = $newcode;
	    return 0;
        }
        else { return 1; }
    }
    else {
        printf "SYSTEM ERROR: status code $newcode not supported";
        exit $ERRORS{'UNKNOWN'};
    }
    return 1; # should never get here
}

#  @DESCRIPTION   : This function is called closer to end of the code after plugin retrieved data and
#		    assigned values to variables. This function checks variables against all thresholds.
#		    It prepares statusdata and statusinfo and exitcode.
#  @LAST CHANGED  : 09-03-12 by WL
#  @INPUT         : none
#  @RETURNS       : nothing (future: 1 on success, 0 on error)
#  @PRIVACY & USE : PUBLIC, To be called after variables have values. Must be used as an object instance function
sub main_checkvars {
    my $self = shift;

    $self->options_finishprocessing() if !exists($self->{'_called_options_finshprocessing'});
    if (exists($self->{'_called_main_checkvars'})) { return; }

    my $thresholds = $self->{'_thresholds'};
    my $dataresults = $self->{'_dataresults'};
    my $allVars = $self->{'_allVars'};
    my $datavars = $self->{'_datavars'};

    my ($dvar,$avar,$aname,$perf_str,$chk)=(undef,undef,undef,undef,undef);

    # main loop to check for warning & critical thresholds
    for (my $i=0;$i<scalar(@{$allVars});$i++) {
	$avar = $allVars->[$i];
	if (!defined($datavars->{$avar}) || scalar(@{$datavars->{$avar}})==0) {
	    if (defined($thresholds->{$avar}{'ABSENT'})) {
                $self->set_statuscode($thresholds->{$avar}{'ABSENT'});
            }
            else {
                $self->set_statuscode("CRITICAL");
            }
	    $aname = $self->out_name($avar);
            $self->addto_statusinfo_output($avar, "$aname data is missing");
        }
	foreach $dvar (@{$datavars->{$avar}}) {
	    $aname = $self->out_name($dvar);
	    if (defined($dataresults->{$dvar}[0])) {
		# main check
		if (defined($avar)) {
		    if ($dataresults->{$dvar}[0] eq 0 && exists($thresholds->{$avar}{'ZERO'})) {
			$self->set_statuscode($thresholds->{$avar}{'ZERO'});
			$self->addto_statusinfo_output($dvar, "$aname is zero") if $self->statuscode() ne 'OK';
		    }
		    else {
			$chk=undef;
			if (exists($thresholds->{$avar}{'CRIT'})) {
			    $chk = $self->check_threshold($aname,lc $dataresults->{$dvar}[0], $thresholds->{$avar}{'CRIT'});
			    if ($chk) {
				$self->set_statuscode("CRITICAL");
				$self->addto_statusinfo_output($dvar,$chk);
			    }
			}
			if (exists($thresholds->{$avar}{'WARN'}) && (!defined($chk) || !$chk)) {
			    $chk = $self->check_threshold($aname,lc $dataresults->{$dvar}[0], $thresholds->{$avar}{'WARN'});
			    if ($chk) {
				$self->set_statuscode("WARNING");
				$self->addto_statusinfo_output($dvar,$chk);
			    }
			}
		    }
		}
		# if we did not output to status line yet, do so
		$self->addto_statusdata_output($dvar,$aname." is ".$dataresults->{$dvar}[0]);

		# if we were asked to output performance, prepare it but do not output until later
		if ((defined($self->{'o_perf'}) && defined($avar) && !exists($thresholds->{$avar}{'PERF'})) ||
		    (exists($thresholds->{$avar}{'PERF'}) && $thresholds->{$avar}{'PERF'} eq 'YES')) {
			$perf_str = perf_name($aname).'='.$dataresults->{$dvar}[0];
			$self->set_perfdata($dvar, $perf_str, undef, "IFNOTSET"); # with undef UOM would get added
			$dataresults->{$dvar}[2]=0; # this would clear -1 from preset perf data, making it ready for output
			# below is where threshold info gets added to perfdata
			if ((exists($thresholds->{$avar}{'WARN'}[5]) && $thresholds->{$avar}{'WARN'}[5] ne '') ||
			    (exists($thresholds->{$avar}{'CRIT'}[5]) && $thresholds->{$avar}{'CRIT'}[5] ne '')) {
				$perf_str = ';';
				$perf_str .= $thresholds->{$avar}{'WARN'}[5] if exists($thresholds->{$avar}{'WARN'}[5]) && $thresholds->{$avar}{'WARN'}[5] ne '';
				$perf_str .= ';'.$thresholds->{$avar}{'CRIT'}[5] if exists($thresholds->{$avar}{'CRIT'}[5]) && $thresholds->{$avar}{'CRIT'}[5] ne '';
				$self->set_perfdata($dvar, $perf_str, '', "ADD");
			}
		}
	    }
	}
    }
    $self->{'_called_main_checkvars'}=1;
    # $statusinfo=trim($statusinfo);
    # $statusdata=trim($statusdata);
}

#  @DESCRIPTION   : This function is at the end. It prepares PERFOUT for output collecting all perf variables data
#  @LAST CHANGED  : 08-26-12 by WL
#  @INPUT         : none
#  @RETURNS       : nothing (future: 1 on success, 0 on error)
#  @PRIVACY & USE : PUBLIC, To be called after variables have values. Must be used as an object instance function
#		    Calling this function direcly is optional, its automatically called on 1st call to perfdata()
sub main_perfvars {
    my $self = shift;

    my $dataresults = $self->{'_dataresults'};
    my $PERF_OK_STATUS_REGEX = $self->{'perfOKStatusRegex'};
    my $perfVars = $self->{'_perfVars'};
    my $known_vars = $self->{'knownStatusVars'};
    my $datavars = $self->{'_datavars'};
    my $avar;
    my $dvar;

    $self->main_checkvars() if !exists($self->{'_called_main_checkvars'});
    if (exists($self->{'_called_main_perfvars'})) { return; }

    for (my $i=0;$i<scalar(@{$perfVars});$i++) {
	$avar=$perfVars->[$i];
	if (!defined($datavars->{$avar}) || scalar(@{$datavars->{$avar}})==0) {
		$self->verb("Perfvar: $avar selected for PERFOUT but data not available");
	}
	else {
	    foreach $dvar (@{$datavars->{$avar}}) {
	    	if (defined($dataresults->{$dvar}[0])) {
		    $self->verb("Perfvar: $dvar ($avar) = ".$dataresults->{$dvar}[0]);
	            if (!defined($known_vars->{$avar}[1]) || $known_vars->{$avar}[1] =~ /$PERF_OK_STATUS_REGEX/ ) {
			$self->addto_perfdata_output($dvar);
		    }
		    else {
			$self->verb(" -- not adding to perfdata because of it is '".$known_vars->{$avar}[1]."' type variable --");
		    }
	        }
	        else {
		    $self->verb("Perfvar: $avar selected for PERFOUT but data not defined");
	        }
	    }
	}
    }
    if (defined($self->{'o_prevperf'})) {
        $self->addto_perfdata_output('_ptime', "_ptime=".time(), "REPLACE");
    }
    foreach $dvar (keys %{$dataresults}) {
        if (defined($dataresults->{$dvar}[3]) && $dataresults->{$dvar}[3] ne '') {
	    $self->verb("Perfvar (Dataresults Loop): $dvar => ".$dataresults->{$dvar}[3]);
            $self->addto_perfdata_output($dvar);
        }
    }

    $self->{'_called_main_perfvars'}=1;
    # $perfdata = trim($perfdata);
}

#  @DESCRIPTION   : This function should be called at the very very end, it returns perf data output
#  @LAST CHANGED  : 08-22-12 by WL
#  @INPUT         : none
#  @RETURNS       : string of perfdata starting with "|"
#  @PRIVACY & USE : PUBLIC, To be called during plugin output. Must be used as an object instance function
sub perfdata {
    my $self=shift;

    $self->main_perfvars() if !exists($self->{'_called_main_perfvars'});
    my $perfdata = trim($self->{'_perfdata'});
    if ($perfdata ne '') {
	return " | " . $perfdata;
    }
    return "";
}

#  @DESCRIPTION   : This function is called after data is available and calculates rate variables
#		    based on current and previous (saved in perfdata) values.
#  @LAST CHANGED  : 08-27-12 by WL
#  @INPUT         : none
#  @RETURNS       : nothing (future: 1 on success, 0 on error)
#  @PRIVACY & USE : PUBLIC, To be called after variables have values. Must be used as an object instance function
sub calculate_ratevars {
    my $self = shift;

    my $prev_perf = $self->{'_prevPerf'};
    my $ptime = $self->{'_perfcheck_time'};
    my $thresholds = $self->{'_thresholds'};
    my $dataresults = $self->{'_dataresults'};
    my $datavars = $self->{'_datavars'};
    my $allVars = $self->{'_allVars'};

    my ($avar,$dvar,$nvar) = (undef,undef,undef);
    my $timenow=time();
    if (defined($self->{'o_prevperf'}) && (defined($self->{'o_perf'}) || defined($self->{'o_perfvars'}))) {
	for (my $i=0;$i<scalar(@{$allVars});$i++) {
	    if ($allVars->[$i] =~ /^&(.*)/) {
		$avar = $1;
		if (defined($datavars->{$avar}) && scalar(@{$datavars->{$avar}})>0) {
		    foreach $dvar (@{$datavars->{$avar}}) {
			$nvar = '&'.$dvar;
			# this forces perfdata output if it was not already
			if (defined($dataresults->{$dvar}) && $dataresults->{$dvar}[2]<1 &&
			    (!defined($dataresults->{$dvar}[3]) || $dataresults->{$dvar}[3] eq '')) {
				$self->set_perfdata($dvar, perf_name($self->out_name($dvar)).'='.$dataresults->{$dvar}[0], undef, "IFNOTSET");
				$self->set_threshold($dvar,'PERF','YES');
				$self->set_threshold($dvar,'SAVED','YES');  # will replace PERF in the future
			}
			if (defined($prev_perf->{$dvar}) && defined($ptime)) {
			    $self->add_data($nvar,
			      sprintf("%.2f",($dataresults->{$dvar}[0]-$prev_perf->{$dvar})/($timenow-$ptime)));
			    $self->verb("Calculating Rate of Change for $dvar ($avar) : ".$nvar."=". $self->vardata($nvar));
			}
		    }
		}
	    }
	}
    }
}

}
##################################### END OF THE LIBRARY FUNCTIONS #########################################

# process --query options (which maybe repeated, that's why loop)
sub option_query {
   my $nlib = shift;

   for(my $i=0;$i<scalar(@o_querykey);$i++) {
	  $nlib->verb("Processing query key option: $o_querykey[$i]");
	  my @ar=split(/,/, $o_querykey[$i]);
	  # how to query
	  my @key_querytype = split(':', uc shift @ar);
	  $nlib->verb("- processing query type specification: ".join(':',@key_querytype));
	  $query[$i] = { 'query_type' => $key_querytype[0] };
	  if ($key_querytype[0] eq 'GET' || $key_querytype[0] eq 'LLEN' ||
	      $key_querytype[0] eq 'SLEN' || $key_querytype[0] eq 'HLEN' ||
	      $key_querytype[0] eq 'ZLEN') {
               if (scalar(@key_querytype)!=1) {
                        print "Incorrect specification. GET, LLEN, SLEN, HLEN, ZLEN do not have any arguments\n";
                        print_usage();
                        exit $ERRORS{"UNKNOWN"};
                }
	  }
	  elsif ($key_querytype[0] eq 'HGET' || $key_querytype[0] eq 'HEXISTS' ||
		 $key_querytype[0] eq 'SEXISTS') {
               if (scalar(@key_querytype)!=2) {
                        print "Incorrect specification of HGET, HEXISTS or SEXIST. Must include hash or set member name as an argument.\n";
                        print_usage();
                        exit $ERRORS{"UNKNOWN"};
                }
                $query[$i]{'element_name'} = $key_querytype[1];
	  }
	  elsif ($key_querytype[0] eq 'LRANGE' || $key_querytype[0] eq 'ZRANGE') {
		if ($key_querytype[0] eq 'ZRANGE' && scalar(@key_querytype)!=4) {
			print "Incorrect specification of ZRANGE. Must include type and start and end (min and max scores).\n";
			print_usage();
			exit $ERRORS{"UNKNOWN"};
		}
                elsif ($key_querytype[0] eq 'LRANGE' && (scalar(@key_querytype)<2 || scalar(@key_querytype)>4)) {
                        print "Incorrect specification of LRANGE. Must include type and start and end range.\n";
                        print_usage();
                        exit $ERRORS{"UNKNOWN"};
                }
		elsif ($key_querytype[1] ne 'MAX' && $key_querytype[1] ne 'MIN' &&
		    $key_querytype[1] ne 'AVG' && $key_querytype[1] ne 'SUM') {
			print "Invalid LRANGE/ZRANGE type $key_querytype[1]. This must be either MAX or MIN or AVG or SUM\n";
			print_usage();
			exit $ERRORS{"UNKNOWN"};
		}
		$query[$i]{'query_subtype'} = $key_querytype[1];
		$query[$i]{'query_range_start'} = $key_querytype[2] if defined($key_querytype[2]);
		$query[$i]{'query_range_end'} = $key_querytype[3] if defined($key_querytype[3]);
	  }
	  else {
		print "Invalid key query $key_querytype[0]. Currently supported are GET, LLEN, SLEN, HLEN, ZLEN, HGET, HEXISTS, SEXISTS,  LRANGE and ZRANGE.\n";
		print_usage();
		exit $ERRORS{"UNKNOWN"};
	  }
	  # key to query and how to name it
	  if (scalar(@ar)==0) {
		print "Invalid query specification. Missing query key name\n";
		print_usage();
		exit $ERRORS{"UNKNOWN"};
	  }
          my ($key_query,$key_name) = split(':', shift @ar);
	  $key_name = $key_query if !defined($key_name) || ! $key_name;
	  $nlib->verb("- variable $key_name will receive data from $key_query");
	  $query[$i]{'key_query'} = $key_query;
	  $query[$i]{'key_name'} = $key_name;
          # parse thresholds and finish processing assigning values to arrays
          my $th = $nlib->parse_thresholds_list(join(',',@ar));
	  if (exists($th->{'ABSENT'})) {
	      $nlib->verb("- ".$th->{'ABSENT'}." alert will be issued if $key_query is not present");
	      $query[$i]{'alert'} = $th->{'ABSENT'};
	  }
	  if (exists($th->{'WARN'})) {
	      $nlib->verb("- warning threshold ".$th->{'WARN'}." set");
	      $query[$i]{'warn'} = $th->{'WARN'};
	  }
	  if (exists($th->{'CRIT'})) {
	      $nlib->verb("- critical threshold ".$th->{'CRIT'}." set");
	      $query[$i]{'crit'} = $th->{'CRIT'};
	  }
	  $nlib->add_thresholds($key_name,$th);
     }
}

# sets password, host, port and other data based on options entered
sub options_setaccess {
    if (!defined($o_host)) { print "Please specify hostname (-H)\n"; print_usage(); exit $ERRORS{"UNKNOWN"}; }
    if (defined($o_pwfile) && $o_pwfile) {
        if ($o_password) {
	    print "use either -x or -C to enter credentials\n"; print_usage(); exit $ERRORS{"UNKNOWN"};
	}
        open my $file, '<', $o_pwfile or die $!;
        while (<$file>) {
            # Match first non-blank line that doesn't start with a comment
            if (!($_ =~ /^\s*#/) && $_ =~ /\S+/) {
                chomp($PASSWORD = $_);
                last;
            }
        }
        close $file;
        print 'Password file is empty' and exit $ERRORS{"UNKNOWN"} if !$PASSWORD;
    }
    if (defined($o_password) && $o_password) {
	$PASSWORD = $o_password;
    }
    $HOSTNAME = $o_host if defined($o_host);
    $PORT     = $o_port if defined($o_port);
    $TIMEOUT  = $o_timeout if defined($o_timeout);
    $DATABASE = $o_database if defined($o_database);
}

# parse command line options
sub check_options {
    my $opt;
    my $nlib = shift;
    my %Options = ();
    Getopt::Long::Configure("bundling");
    GetOptions(\%Options,
   	'v:s'	=> \$o_verb,		'verbose:s' => \$o_verb, "debug:s" => \$o_verb,
        'h'     => \$o_help,            'help'          => \$o_help,
        'H:s'   => \$o_host,            'hostname:s'    => \$o_host,
        'p:i'   => \$o_port,            'port:i'        => \$o_port,
        'C:s'   => \$o_pwfile,          'credentials:s' => \$o_pwfile,
        'x:s'   => \$o_password,	'password:s'	=> \$o_password,
	'D:s'	=> \$o_database,	'database:s'	=> \$o_database,
        't:i'   => \$o_timeout,         'timeout:i'     => \$o_timeout,
        'V'     => \$o_version,         'version'       => \$o_version,
	'a:s'   => \$o_variables,       'variables:s'   => \$o_variables,
        'c:s'   => \$o_crit,            'critical:s'    => \$o_crit,
        'w:s'   => \$o_warn,            'warn:s'        => \$o_warn,
	'f:s'   => \$o_perf,            'perfparse:s'   => \$o_perf,
	'A:s'   => \$o_perfvars,        'perfvars:s'    => \$o_perfvars,
        'T:s'   => \$o_timecheck,       'response_time:s' => \$o_timecheck,
        'R:s'   => \$o_hitrate,         'hitrate:s'     => \$o_hitrate,
        'r:s'   => \$o_repdelay,        'replication_delay:s' => \$o_repdelay,
        'P:s'   => \$o_prevperf,        'prev_perfdata:s' => \$o_prevperf,
        'E:s'   => \$o_prevtime,        'prev_checktime:s'=> \$o_prevtime,
        'm:s'   => \$o_memutilization,  'memory_utilization:s' => \$o_memutilization,
	'M:s'	=> \$o_totalmemory,	'total_memory:s' => \$o_totalmemory,
	'q=s'	=> \@o_querykey,	'query=s'	 => \@o_querykey,
	'o=s'	=> \@o_check,		'check|option=s' => \@o_check,
	'rate_label:s'	=> \$o_ratelabel,
	map { ($_) } $nlib->additional_options_list()
    );

    ($o_rprefix,$o_rsuffix)=split(/,/,$o_ratelabel) if defined($o_ratelabel) && $o_ratelabel ne '';

    # Standard nagios plugin required options
    if (defined($o_help)) { help($nlib); exit $ERRORS{"UNKNOWN"} };
    if (defined($o_version)) { p_version(); exit $ERRORS{"UNKNOWN"} };

    # now start options processing in the library
    $nlib->options_startprocessing(\%Options, $o_verb, $o_variables, $o_warn, $o_crit, $o_perf, $o_perfvars, $o_rprefix, $o_rsuffix);

    # additional variables/options calculated and added by this plugin
    if (defined($o_timecheck) && $o_timecheck ne '') {
          $nlib->verb("Processing timecheck thresholds: $o_timecheck");
	  $nlib->add_thresholds('response_time',$o_timecheck);
    }
    if (defined($o_hitrate) && $o_hitrate ne '') {
          $nlib->verb("Processing hitrate thresholds: $o_hitrate");
	  $nlib->add_thresholds('hitrate',$o_hitrate);
	  $nlib->set_threshold('hitrate','ZERO','OK') if !defined($nlib->get_threshold('hitrate','ZERO')); # except case of hitrate=0, don't remember why I added it
    }
    if (defined($o_memutilization) && $o_memutilization ne '') {
          $nlib->verb("Processing memory utilization thresholds: $o_memutilization");
          $nlib->add_thresholds('memory_utilization',$o_memutilization);
    }
    if (defined($o_totalmemory)) {
	if ($o_totalmemory =~ /^(\d+)B/) {
	   $o_totalmemory = $1;
	}
	elsif ($o_totalmemory =~ /^(\d+)K/) {
	   $o_totalmemory = $1*1024;
	}
	elsif ($o_totalmemory =~ /^(\d+)M/) {
	   $o_totalmemory = $1*1024*1024;
	}
	elsif ($o_totalmemory =~ /^(\d+)G/) {
	   $o_totalmemory = $1*1024*1024*1024;
	}
	elsif ($o_totalmemory !~ /^(\d+)$/) {
		print "Total memory value $o_totalmemory can not be interpreted\n";
		print_usage();
		exit $ERRORS{"UNKNOWN"};
	}
    }
    if (defined($o_repdelay) && $o_repdelay ne '') {
          $nlib->verb("Processing replication delay thresholds: $o_repdelay");
          $nlib->add_thresholds('replication_delay',$o_repdelay);
    }

    # general check option, allows to specify everything, can be repeated more than once
    foreach $opt (@o_check) {
	  $nlib->verb("Processing general check option: ".$opt);
	  $nlib->add_thresholds(undef,$opt);
    }

    # query option processing
    option_query($nlib);

    # finish it up
    $nlib->options_finishprocessing();
    options_setaccess();
}

# Get the alarm signal (just in case nagios screws up)
$SIG{'ALRM'} = sub {
     $redis->quit if defined($redis);
     print ("ERROR: Alarm signal (Nagios time-out)\n");
     exit $ERRORS{"UNKNOWN"};
};

########## MAIN #######

my $nlib = Naglio->lib_init('plugin_name' => 'check_redis.pl',
			    'plugins_authors' => 'William Leibzon',
			    'plugin_description' => 'Redis Monitoring Plugin for Nagios',
			    'usage_function' => \&print_usage,
                            'enable_long_options' => 1,
                            'enable_rate_of_change' => 1);
$nlib->set_knownvars(\%KNOWN_STATUS_VARS, $PERF_OK_STATUS_REGEX);

check_options($nlib);
$nlib->verb("check_redis.pl plugin version ".$Version);

# Check global timeout if plugin screws up
if (defined($TIMEOUT)) {
  $nlib->verb("Alarm at $TIMEOUT");
  alarm($TIMEOUT);
}
else {
  $nlib->verb("no timeout defined : $o_timeout + 10");
  alarm ($o_timeout+10);
}

# some more variables for processing of the results
my $dbversion = "";
my $vnam;
my $vval;
my %dbs=();	# database-specific info, this is almost unused right now
my %slaves=();
my $avar;

# connect using tcp and verify the port is working
my $sock = new IO::Socket::INET(
  PeerAddr => $HOSTNAME,
  PeerPort => $PORT,
  Proto => 'tcp',
);
if (!$sock) {
  print "CRITICAL ERROR - Can not connect to '$HOSTNAME' on port $PORT\n";
  exit $ERRORS{'CRITICAL'};
}
close($sock);

# now do connection using Redis library
my $start_time;
my $dsn = $HOSTNAME.":".$PORT;
$nlib->verb("connecting to $dsn");
$start_time = [ Time::HiRes::gettimeofday() ] if defined($o_timecheck);

$redis = Redis-> new ( server => $dsn, 'debug' => (defined($o_verb))?1:0 );

if ($PASSWORD) {
    $redis->auth($PASSWORD);
}
if ($DATABASE) {
    $redis->select($DATABASE);
}

if (!$redis) {
  print "CRITICAL ERROR - Redis Library - can not connect to '$HOSTNAME' on port $PORT\n";
  exit $ERRORS{'CRITICAL'};
}

if (!$redis->ping) {
  print "CRITICAL ERROR - Redis Library - can not ping '$HOSTNAME' on port $PORT\n";
  exit $ERRORS{'CRITICAL'};
}

# This returns hashref of various statistics/info data
my $stats = $redis->info();

# Check specified key if option -q was used
for (my $i=0; $i<scalar(@query);$i++) {
  my $result=undef;
  if ($query[$i]{'query_type'} eq 'GET') {
	$nlib->verb("Getting redis key: ".$query[$i]{'key_query'});
  	$result = $redis->get($query[$i]{'key_query'});
  }
  elsif ($query[$i]{'query_type'} eq 'LLEN') {
	$nlib->verb("Getting number of items for list with redis key: ".$query[$i]{'key_query'});
  	$result = $redis->llen($query[$i]{'key_query'});
  }
  elsif ($query[$i]{'query_type'} eq 'HLEN') {
        $nlib->verb("Getting number of items for hash with redis key: ".$query[$i]{'key_query'});
        $result = $redis->hlen($query[$i]{'key_query'});
  }
  elsif ($query[$i]{'query_type'} eq 'SLEN') {
        $nlib->verb("Getting number of items for set with redis key: ".$query[$i]{'key_query'});
        $result = $redis->scard($query[$i]{'key_query'});
  }
  elsif ($query[$i]{'query_type'} eq 'ZLEN') {
        $nlib->verb("Getting number of items for sorted set with redis key: ".$query[$i]{'key_query'});
        $result = $redis->zcard($query[$i]{'key_query'});
  }
  elsif ($query[$i]{'query_type'} eq 'HGET') {
        $nlib->verb("Getting hash member ".$query[$i]{'element_name'}." with redis key: ".$query[$i]{'key_query'});
        $result = $redis->hget($query[$i]{'key_query'},$query[$i]{'element_name'});
  }
  elsif ($query[$i]{'query_type'} eq 'HEXISTS') {
        $nlib->verb("Checking if there exists hash member ".$query[$i]{'element_name'}." with redis key: ".$query[$i]{'key_query'});
        $result = $redis->hexists($query[$i]{'key_query'},$query[$i]{'element_name'});
  }
  elsif ($query[$i]{'query_type'} eq 'SEXISTS') {
        $nlib->verb("Checking if there exists set member ".$query[$i]{'element_name'}." with redis key: ".$query[$i]{'key_query'});
        $result = $redis->sismember($query[$i]{'key_query'},$query[$i]{'element_name'});
  }
  elsif ($query[$i]{'query_type'} eq 'LRANGE' || $query[$i]{'query_type'} eq 'ZRANGE') {
	my $range_start;
	my $range_end;
	if (defined($query[$i]{'query_range_start'}) && $query[$i]{'query_range_start'} ne '') {
	    $range_start=$query[$i]{'query_range_start'};
	}
        else {
	    $range_start=0;
	}
	if (defined($query[$i]{'query_range_end'}) && $query[$i]{'query_range_end'} ne '') {
	    $range_end= $query[$i]{'query_range_end'};
	}
	elsif ($query[$i]{'query_type'} eq 'LRANGE') {
	    $nlib->verb("Getting (lrange) redis key: ".$query[$i]{'key_query'});
	    $range_end = $redis->llen($query[$i]{'key_query'})-1;
	}
	else {
	    print "ERROR - can not do ZRANGE if you do not specify mix and max score.";
	    exit $ERRORS{"UNKNOWN"};
	}
	my @list;
	if ($query[$i]{'query_type'} eq 'LRANGE') {
	   @list = $redis->lrange($query[$i]{'key_query'}, $range_start, $range_end);
	}
	else {
	   @list = $redis->zrange($query[$i]{'key_query'}, $range_start, $range_end);
	}
	if (scalar(@list)>0) {
		$result=shift @list;
		foreach(@list) {
		    $result+=$_ if $query[$i]{'query_subtype'} eq 'SUM' || $query[$i]{'query_subtype'} eq 'AVG';
		    $result=$_ if ($query[$i]{'query_subtype'} eq 'MIN' && $_ < $result) ||
				  ($query[$i]{'query_subtype'} eq 'MAX' && $_ > $result);
		}
		$result = $result / (scalar(@list)+1) if $query[$i]{'query_subtype'} eq 'AVG';
	}
  }
  if (defined($result)) {
      $query[$i]{'result'} = $result;
      $nlib->add_data($query[$i]{'key_name'}, $result);
      $nlib->verb("Result of querying ".$query[$i]{'key_query'}." is: $result");
  }
  else {
      $nlib->verb("could not get results for ".$query[$i]{'key_query'});
  }
  # else {
  #    if (exists($query[$i]{'alert'}) && $query[$i]{'alert'} ne 'OK') {
  #	$statuscode=$query[$i]{'alert'} if $statuscode ne 'CRITICAL';
  #	$statusinfo.=", " if $statusinfo;
  #	$statusinfo.= "Query on ".$query[$i]{'key_query'}." did not succeed";
  #    }
  # }
}

# end redis session
$redis->quit;

# load stats data into internal hash array
my $total_keys=0;
my $total_expires=0;
foreach $vnam (keys %{$stats}) {
     $vval = $stats->{$vnam};
     if (defined($vval)) {
    	$nlib->verb("Stats Line: $vnam = $vval");
	if (exists($KNOWN_STATUS_VARS{$vnam}) && $KNOWN_STATUS_VARS{$vnam}[1] eq 'VERSION') {
		$dbversion .= $vval;
	}
	elsif ($vnam =~ /^db\d+$/) {
		$dbs{$vnam}= {'name'=>$vnam};
		foreach (split(/,/,$vval)) {
			my ($k,$d) = split(/=/,$_);
			$nlib->add_data($vnam.'_'.$k,$d);
			$dbs{$vnam}{$k}=$d;
			$nlib->verb(" - stats data added: ".$vnam.'_'.$k.' = '.$d);
			$total_keys+=$d if $k eq 'keys' && Naglio::isnum($d);
			$total_expires+=$d if $k eq 'expires' && Naglio::isnum($d);
		}
	}
	elsif ($vnam =~ /~slave/) {
		# TODO TODO TODO TODO
	}
	else {
		$nlib->add_data($vnam, $vval);
   	}
     }
     else {
        $nlib->verb("Stats Data: $vnam = NULL");
     }
}
$nlib->verb("Calculated Data: total_keys=".$total_keys);
$nlib->verb("Calculated Data: total_expires=".$total_expires);
$nlib->add_data('total_keys',$total_keys);
$nlib->add_data('total_expires',$total_expires);

# Response Time
if (defined($o_timecheck)) {
    $nlib->add_data('response_time',Time::HiRes::tv_interval($start_time));
    $nlib->addto_statusdata_output('response_time',sprintf("response in %.3fs",$nlib->vardata('response_time')));
    if (defined($o_perf)) {
        $nlib->set_perfdata('response_time','response_time='.$nlib->vardata('response_time'),'s');
    }
}

# calculate rate variables
$nlib->calculate_ratevars();

# Hitrate
my $hitrate=0;
my $hits_total=0;
my $hits_hits=undef;
my $hitrate_all=0;
if (defined($o_hitrate) && defined($nlib->vardata('keyspace_hits')) && defined($nlib->vardata('keyspace_misses'))) {
    for $avar ('keyspace_hits', 'keyspace_misses') {
        if (defined($o_prevperf) && defined($o_perf)) {
                $nlib->set_perfdata($avar,$avar."=".$nlib->vardata($avar),'c');
        }
        $hits_hits = $nlib->vardata('keyspace_hits') if $avar eq 'keyspace_hits';
        $hits_total += $nlib->vardata($avar);
    }
    $nlib->verb("Calculating Hitrate : total=".$hits_total." hits=".$hits_hits);
    if (defined($hits_hits) && defined($nlib->prev_perf('keyspace_hits')) && defined($nlib->prev_perf('keyspace_misses')) && $hits_hits > $nlib->prev_perf('keyspace_hits')) {
        $hitrate_all = $hits_hits/$hits_total*100 if $hits_total!=0;
        $hits_hits -= $nlib->prev_perf('keyspace_hits');
        $hits_total -= $nlib->prev_perf('keyspace_misses');
        $hits_total -= $nlib->prev_perf('keyspace_hits');
        verb("Calculating Hitrate. Adjusted based on previous values. total=".$hits_total." hits=".$hits_hits);
    }
    if (defined($hits_hits)) {
    	if ($hits_total!=0) {
	    $hitrate= sprintf("%.4f", $hits_hits/$hits_total*100);
	}
	$nlib->add_data('hitrate',$hitrate);
	my $sdata .= sprintf(" hitrate is %.2f%%", $hitrate);
	$sdata .= sprintf(" (%.2f%% from launch)", $hitrate_all) if ($hitrate_all!=0);
	$nlib->addto_statusdata_output('hitrate',$sdata);
	if (defined($o_perf)) {
		$nlib->set_perfdata('hitrate',"hitrate=$hitrate",'%');
	}
     }
}

# Replication Delay
my $repl_delay=0;
if (defined($o_repdelay) && defined($nlib->vardata('master_last_io_seconds_ago')) && defined($nlib->vardata('role'))) {
    if ($nlib->vardata('role') eq 'slave') {
	$repl_delay = $nlib->vardata('master_link_down_since_seconds');
	if (!defined($repl_delay) || $repl_delay < $nlib->vardata('master_last_io_seconds_ago')) {
	    $repl_delay = $nlib->vardata('master_last_io_seconds_ago','s');
	}
	if (defined($repl_delay) && $repl_delay>=0) {
	    $nlib->add_data('replication_delay',$repl_delay);
	    $nlib->addto_statusdata_output('replication_delay',sprintf("replication_delay is %d", $nlib->vardata('replication_delay')));
	    if (defined($o_perf)) {
		$nlib->set_perfdata('replication_delay',sprintf("replication_delay=%d", $nlib->vardata('replication_delay')));
	    }
	}
    }
}

# Memory Use Utilization
if (defined($o_memutilization) && defined($nlib->vardata('used_memory_rss'))) {
    if (defined($o_totalmemory)) {
        $nlib->add_data('memory_utilization',$nlib->vardata('used_memory_rss')/$o_totalmemory*100);
	$nlib->verb('memory utilization % : '.$nlib->vardata('memory_utilization').' = '.$nlib->vardata('used_memory_rss').' (used_memory_rss) / '.$o_totalmemory.' * 100');
    }
    elsif ($o_memutilization ne '') {
	print "ERROR: Can not calculate memory utilization if you do not specify total memory on a system (-M option)\n";
	print_usage();
	exit $ERRORS{"UNKNOWN"};
    }
    if (defined($o_perf) && defined($nlib->vardata('memory_utilization'))) {
	$nlib->set_perfdata('memory_utilization',sprintf(" memory_utilization=%.4f", $nlib->vardata('memory_utilization')),'%');
    }
    if (defined($nlib->vardata('used_memory_human')) && defined($nlib->vardata('used_memory_peak_human'))) {
	my $sdata="memory use is ".$nlib->vardata('used_memory_human')." (";
	$sdata.='peak '.$nlib->vardata('used_memory_peak_human');
	if (defined($nlib->vardata('memory_utilization'))) {
		$sdata.= sprintf(", %.2f%% of max", $nlib->vardata('memory_utilization'));
	}
	if (defined($nlib->vardata('mem_fragmentation_ratio'))) {
		$sdata.=", fragmentation ".$nlib->vardata('mem_fragmentation_ratio').'%';
	}
	$sdata.=")";
	$nlib->addto_statusdata_output('memory_utilization',$sdata);
    }
}

# Check thresholds in all variables and prepare status and performance data for output
$nlib->main_checkvars();
$nlib->main_perfvars();

# now output the results
print $nlib->statuscode() . ': '.$nlib->statusinfo();
print " - " if $nlib->statusinfo();
print "REDIS " . $dbversion . ' on ' . $HOSTNAME. ':'. $PORT;
print ' has '.scalar(keys %dbs).' databases ('.join(',',keys(%dbs)).')';
print " with $total_keys keys" if $total_keys > 0;
print ', up '.$nlib->uptime_info($nlib->vardata('uptime_in_seconds')) if defined($nlib->vardata('uptime_in_seconds'));
print " - " . $nlib->statusdata() if $nlib->statusdata();
print $nlib->perfdata();
print "\n";

# end exit
exit $ERRORS{$nlib->statuscode()};
