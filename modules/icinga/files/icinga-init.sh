#! /bin/sh
# On Debian /usr/bin/sh -> dash, and dash supports `echo -n`, even though it is
# a POSIX shell, so disable the shellcheck warning:
# shellcheck disable=SC3037
#		Written by Miquel van Smoorenburg <miquels@cistron.nl>.
#		Modified for Debian GNU/Linux
#		by Ian Murdock <imurdock@gnu.ai.mit.edu>.
#               Clamav version by Magnus Ekdahl <magnus@debian.org>
#		Nagios version by Sean Finney <seanius@debian.org> and probably others
#		nagios2 version by Marc Haber <mh+debian-packages@zugschlus.de>
#		icinga version by Alexander Wirt <formorer@debian.org>
#
#		WMF version by Leslie Carr <lcarr@wikimedia.org>

### BEGIN INIT INFO
# Provides:          icinga
# Required-Start:    $local_fs $remote_fs $syslog $named $network $time
# Required-Stop:     $local_fs $remote_fs $syslog $named $network
# Should-Start:      
# Should-Stop:       
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: icinga host/service/network monitoring and management system
# Description:       icinga is a monitoring and management system for hosts, services and networks.
### END INIT INFO

set -e

. /lib/lsb/init-functions

DAEMON=/usr/sbin/icinga
NAME="icinga"
DESC="icinga monitoring daemon"
ICINGACFG="/etc/icinga/icinga.cfg"
CGICFG="/etc/icinga/cgi.cfg"
NICENESS=0
#Purge old resources before start
ICINGAPUPPETFILES="/etc/icinga/puppet_hosts.cfg /etc/nagios/puppet_hostgroups.cfg /etc/nagios/puppet_servicegroups.cfg /etc/icinga/puppet_services.cfg"
#NAGIOSPUPPETFILES="/etc/nagios/puppet_hosts.cfg /etc/nagios/puppet_hostgroups.cfg /etc/nagios/puppet_servicegroups.cfg /etc/nagios/puppet_checks.d/*"
PURGESCRIPT="/usr/local/sbin/purge-nagios-resources.py"
[ -x "$DAEMON" ] || exit 0
[ -r /etc/default/icinga ] && . /etc/default/icinga

# this is from madduck on IRC, 2006-07-06
# There should be a better possibility to give daemon error messages
# and/or to log things
log()
{
  case "$1" in
    [[:digit:]]*) success=$1; shift;;
    *) :;;
  esac
  log_action_begin_msg "$1"; shift
  log_action_end_msg ${success:-0} "$*"
}

check_started () {
  if [ -e "$CGICFG" ]
  then
  	check_cmd=$(get_config icinga_check_command $CGICFG)
  	if [ ! "$check_cmd" ]; then
    		log 6 "unable to determine icinga_check_command from $CGICFG!" 
    		return 6
	fi
   else 
        check_cmd="/usr/lib/nagios/plugins/check_nagios /var/cache/icinga/status.dat 5 '/usr/sbin/icinga'"
   fi

  eval $check_cmd >/dev/null
		
  if [ -f "$THEPIDFILE" ]; then
    pid="$(cat $THEPIDFILE)"
    if [ "$pid" ] && kill -0 $pid >/dev/null 2>/dev/null; then
      return 0    # Is started
    fi
  fi
  return 1	# Isn't started
}

#
#	get_config()
#
#	grab a config option from icinga.cfg (or possibly another icinga config
#	file if specified).  everything after the '=' is echo'd out, making
#	this a nice generalized way to get requested settings.
#
get_config () {
  if [ "$2" ]; then
    set -- `grep ^$1 $2 | sed 's@=@ @'`
  else
    set -- `grep ^$1 $ICINGACFG | sed 's@=@ @'`
  fi
  shift
  echo $*
}

check_config () {
  if $DAEMON -v $ICINGACFG >/dev/null 2>&1 ; then
    # First get the user/group etc Icinga is running as
    nagios_user="$(get_config icinga_user)"
    nagios_group="$(get_config icinga_group)"
    log_file="$(get_config log_file)"
    log_dir="$(dirname $log_file)"

    return 0    # Config is ok
  else
    # config is not okay, so let's barf the error to the user
    $DAEMON -v $ICINGACFG
  fi
}

check_named_pipe () {
  icingapipe="$(get_config command_file)"
  if [ -p "$icingapipe" ]; then
    return 1   # a named pipe exists
  elif [ -e "$icingapipe" ];then
    return 1
  else
    return 0   # no named pipe exists
  fi
}

if [ ! -f "$ICINGACFG" ]; then
  log_failure_msg "There is no configuration file for Icinga."
  exit 6
fi

THEPIDFILE=$(get_config "lock_file")
[ -n "$THEPIDFILE" ] || THEPIDFILE='/var/run/icinga/icinga.pid'

start () {

#clean up old files
  $PURGESCRIPT $ICINGAPUPPETFILES

  DIRECTORY=$(dirname $THEPIDFILE)
  [ ! -d $DIRECTORY ] && mkdir -p $DIRECTORY
  chown icinga:nagios $DIRECTORY

  if ! check_started; then
    if ! check_named_pipe; then
      log_action_msg "named pipe exists - removing"
      rm -f $icingapipe
    fi
    if check_config; then
      start_daemon -n $NICENESS -p $THEPIDFILE $DAEMON -d $ICINGACFG
      ret=$?
    else
      log_failure_msg "errors in config!"
      log_end_msg 1
      exit 1
    fi
  else
    log_warning_msg "already running!"
  fi
  return $ret
}

stop () {
    killproc -p $THEPIDFILE
    ret=$?
    if [ `pidof icinga | wc -l ` -gt 0 ]; then
        echo -n "Waiting for $NAME daemon to die.."
        cnt=0
        while [ `pidof icinga | wc -l ` -gt 0 ]; do
            cnt=`expr "$cnt" + 1`
            if [ "$cnt" -gt 15 ]; then
                kill -9 `pidof icinga`
                break
            fi
            sleep 1
            echo -n "."
        done
    fi
    echo
    if ! check_named_pipe; then
      rm -f $icingapipe
    fi
    test -e $THEPIDFILE && rm $THEPIDFILE
    if [ -n "$ret" ]; then
      return $ret
    else
      return $?
    fi
}

status()
{
  log_action_begin_msg "checking $DAEMON"
  if check_started; then
    log_action_end_msg 0 "running"
  else
    if [ -e "$THEPIDFILE" ]; then
      log_action_end_msg 1 "$DAEMON failed"
      exit 1
    else
      log_action_end_msg 1 "not running"
      exit 3
    fi
  fi
}

check () {
  $DAEMON -v $ICINGACFG
}

reload () {
  # Check first
  if check_config; then
    if check_started; then
      killproc -p $THEPIDFILE $DAEMON 1 
    else
      log_warning_msg "Not running."
    fi
  else
    log_failure_msg "errors in config!"
    log_end_msg 6
    exit 6
 fi
}

case "$1" in
  start)
    log_daemon_msg "Starting $DESC" "$NAME"
    start
    log_end_msg $?
    ;;
  stop)
    log_daemon_msg "Stopping $DESC" "$NAME"
    stop
    log_end_msg $?
  ;;
  restart)
    log_daemon_msg "Restarting $DESC" "$NAME"
    stop
    if [ -z "$?" -o "$?" = "0" ]; then
      start
    fi
    log_end_msg $?
  ;;
  reload|force-reload)
    log_daemon_msg "Reloading $DESC configuration files" "$NAME"
    reload
    log_end_msg $?
  ;;
  status)
    status
    ;;
  check)
    check
    ;;
  *)
    log_failure_msg "Usage: $0 {start|stop|restart|reload|force-reload|status}" >&2
    exit 1
  ;;
esac

exit 0
