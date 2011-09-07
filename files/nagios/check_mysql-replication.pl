#!/usr/bin/perl

#  -------------------------------------------------------
#             -=- <check_mysql-replication.pl> -=-
#  -------------------------------------------------------
#
#  Description : yet another plugin to check your mysql
#  replication threads and your lag synchronisation
#
#  Version : 0.1
#  -------------------------------------------------------
#  In :
#     - see the How to use section
#
#  Out :
#     - only print on the standard output 
#
#  Features :
#     - perfdata output
#
#  Fix Me/Todo :
#     - too many things ;) but let me know what do you think about it
#     - what about a comparaison with the master status ?
#
# ####################################################################

# ####################################################################
# GPL v3
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
# ####################################################################

# ####################################################################
# How to use :
# ------------
#
# 1 - first you have to create an user with the REPLICATION CLIENT
#     (or you can just grant this privilege)
# mysql> GRANT REPLICATION CLIENT ON *.* TO 'replicateur'@'localhost'
#
# 2 - then just run the script :
# $./check_mysql-replication.pl --help
# ####################################################################

# ####################################################################
# Changelog :
# -----------
#
# --------------------------------------------------------------------
#   Date:22/06/2009   Version:0.1     Author:Erwan Ben Souiden
#   >> creation
# ####################################################################

# ####################################################################
#            Don't touch anything under this line!
#        You shall not pass - Gandalf is watching you
# ####################################################################

use strict;
use DBI;
use Getopt::Long qw(:config no_ignore_case);

# Generic variables
# -----------------
my $version = '0.1';
my $author = 'Erwan Labynocle Ben Souiden';
my $a_mail = 'erwan@aleikoum.net';
my $script_name = 'check_mysql-replication.pl';
my $verbose_value = 0;
my $version_value = 0;
my $more_value = 0;
my $help_value = 0;
my $perfdata_value = 0;
my %ERRORS=('OK'=>0,'WARNING'=>1,'CRITICAL'=>2,'UNKNOWN'=>3,'DEPENDENT'=>4);

# Plugin default variables
# ------------------------
my $display = 'CHECK MySQL REPLICATION - ';
my ($critical,$warning) = (10,5);
my $action = 'process';
my ($slave_address,$slave_port,$slave_login,$slave_pwd) = ("127.0.0.1",3306,"user1","password1");

GetOptions (
    'sa=s' => \ $slave_address,
    'slave-address=s' => \ $slave_address,
    'sp=i' => \ $slave_port,
    'slave-port=i' => \ $slave_port,
    'sl=s' => \ $slave_login,
    'slave-login=s' => \ $slave_login,
    'spd=s' => \ $slave_pwd,
    'slave-password=s' => \ $slave_pwd,
    'w=i' => \ $warning,
    'warning=i' => \ $warning,
    'c=i' => \ $critical,
    'critical=i' => \ $critical,
    'action=s' => \ $action,
    'a=s' => \ $action,
    'm' => \ $more_value,
    'more' => \ $more_value,
    'V' => \ $version_value,
    'version' => \ $version_value,
    'h' => \ $help_value,
    'H' => \ $help_value,
    'help' => \ $help_value,
    'display=s' => \ $display,
    'D=s' => \ $display,
    'perfdata' => \ $perfdata_value,
    'p' => \ $perfdata_value,
    'v' => \ $verbose_value,
    'verbose' => \ $verbose_value
);

print_usage() if ($help_value);
print_version() if ($version_value);


# Syntax check of your specified options
# --------------------------------------

print "DEBUG : slave data : $slave_login:$slave_pwd\@$slave_address:$slave_port \n" if ($verbose_value);
if (($slave_address eq "") or ($slave_port eq "") or ($slave_login eq "")) {
    print $display.'one or more following arguments are missing :slave_address/slave_port/slave_login'."\n";
    exit $ERRORS{"UNKNOWN"};
}

if (($slave_port < 0) or ($slave_port > 65535)) {
    print $display.'the port must be 0 < port < 65535'."\n";
    exit $ERRORS{"UNKNOWN"};
}

print "DEBUG : warning threshold : $warning, critical threshold : $critical \n" if ($verbose_value);
if (($critical < 0) or ($warning < 0) or ($critical < $warning)) {
    print $display.'the thresholds must be integers and the critical threshold higher or equal than the warning threshold'."\n";
    exit $ERRORS{"UNKNOWN"};
}

# Core script
# -----------
my $return = "";
my $plugstate = "OK";

print "DEBUG : action = $action\n" if ($verbose_value);

# process action
# --------------
if ($action eq 'process') {

    my $flag = 0;

    # About the slave
    my $result = request_executor ("$slave_address",$slave_port,$slave_login,$slave_pwd,"SHOW SLAVE STATUS;");
    my ($s_slave_io_running,$s_slave_sql_running) = ($result->{Slave_IO_Running},$result->{Slave_SQL_Running});
    my ($master_address,$master_port,$master_login) = ($result->{Master_Host},$result->{Master_Port},$result->{Master_User});
    my ($s_last_errno,$s_last_error) = ($result->{Last_Errno},$result->{Last_Error});

    # now we can analyse
    $flag ++ if ($s_slave_io_running ne 'Yes');
    $flag ++ if ($s_slave_sql_running ne 'Yes');

    $return .= 'Slave_IO_Running state : '.$s_slave_io_running.', Slave_SQL_Running state : '.$s_slave_sql_running;

    if ($flag > 0) {
        $plugstate = "CRITICAL";
        $return .= 'last_errno : '.$s_last_errno.', last error : '.$s_last_error if (($s_last_errno) or ($s_last_error));
    }

    $return .= ' ; synchronized with '.$master_login.'@'.$master_address.':'.$master_port if ($more_value);
}

# lag action
# ----------
elsif ($action eq 'lag') { 

    # About the slave
    my $result = request_executor ("$slave_address",$slave_port,$slave_login,$slave_pwd,"SHOW SLAVE STATUS;");
    my $s_slave_sbm = $result->{Seconds_Behind_Master};
    my ($master_address,$master_port,$master_login) = ($result->{Master_Host},$result->{Master_Port},$result->{Master_User});

    $return .= ' Seconds_Behind_Master : '.$s_slave_sbm.'s';

    # now we can analyse
    $plugstate = "WARNING" if (($s_slave_sbm >= $warning) and ($s_slave_sbm < $critical));
    $plugstate = "CRITICAL" if ($s_slave_sbm >= $critical);
    $plugstate = "CRITICAL" if (lc($s_slave_sbm) eq "null");

    $return .= ' ; synchronized with '.$master_login.'@'.$master_address.':'.$master_port if ($more_value);
    $return .= ' | behindMaster='.$s_slave_sbm.'s' if ($perfdata_value);
}

# default
# -------
else {
    print $display.'problem ! action value must be "process" or "lag"';
    exit $ERRORS{"UNKNOWN"};
}

print $display.$action." - ".$plugstate." - ".$return;
exit $ERRORS{$plugstate};

# ####################################################################
# function 1 :  display the help
# ------------------------------
sub print_usage() {
    print <<EOT;
$script_name version $version by $author

This plugin checks your mysql replication threads and your lag synchronisation

Usage: /<path-to>/$script_name [-a process|lag] [-p] [-D "$display"] [-v] [-m] [-c 10] [-w 5]

Options:
 -h, --help
    Print detailed help screen
 -V, --version
    Print version information
 -D, --display=STRING
    to modify the output display... 
    default is "CHECK MySQL REPLICATION - "
 -sa, --slave-address=STRING
    address or name of the slave mysql server
    default is 127.0.0.1
 -sp, --slave-port=STRING
    port number of the slave mysql server
    default is 3306
 -sl, --slave-login=STRING
    mysql login
    default is user1
 -spd, --slave-password=STRING
    mysql password
    default is password1
 -a, --action=STRING
    specify the action : process|lag
    default is process
    process : display state of slave threads
    lag : display the number of second behind the master
 -c, --critical=INT
    specify a threshold for the lag action.
    default is 10
 -w, --warning=INT
    specify a threshold for the lag action.
    default is 5
 -m, --more
    Print a longer output. By default, the output is not complet because
    Nagios may truncate it. This option is just for you
 -p, --perfdata
    If you want to activate the perfdata output
 -v, --verbose
    Show details for command-line debugging (Nagios may truncate the output)
    
Send email to $a_mail if you have questions
regarding use of this software. To submit patches or suggest improvements,
send email to $a_mail
This plugin has been created by $author

Hope you will enjoy it ;)

Remember :
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.


EOT
    exit $ERRORS{"UNKNOWN"};
}

# function 2 :  display version information
# -----------------------------------------
sub print_version() {
    print <<EOT;
$script_name version $version
EOT
    exit $ERRORS{"UNKNOWN"};
}

# function 3 :  request executor
# ------------------------------
sub request_executor() {
    my ($host,$port,$user,$pwd,$request) = @_;
    my $dsn = "DBI:mysql:database=mysql;host=$host:$port";
    my $dbh = DBI->connect($dsn, $user, $pwd) or die "connexion failed $DBI::errstr\n";
    my $sth = $dbh->prepare($request);
    $sth->execute();
    my $result = $sth->fetchrow_hashref();
    $sth->finish;
    $dbh->disconnect;
    return $result;
}
