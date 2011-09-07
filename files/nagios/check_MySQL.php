<?php

#--------------
# Init vars
#--------------

$self = array_shift( $argv );

$host = '';
$user = '';
$pass = '';
$slave = false;
$master = false;
$rwslave = false;
$wconnected = 400;
$cconnected = 1000;
$wrunning   = 30;
$crunning   = 75;

# Don't pollute the output with PHP warnings
ini_set( 'display_errors', 'stderr' );

#--------------
# Functions
#--------------

function mysql_gather_status( $server, $user, $password ) {
        $result = array( 'status' => 0 );
        $link = mysql_connect( $server, $user, $password );
        if ( !$link ) {         
                $result['status'] = 2;
		$result['error'] = mysql_error();
		return $result;
        } else {                

		# status

                $myres = mysql_query( "show status" );
                
                if ( !$myres ) {
                        $result['status'] = 2;
                        $result['error'] = mysql_error( $link );
                        return $result;
                }
        
                while ( $row = mysql_fetch_row( $myres ) ) {
                        $result[$row[0]] = $row[1];
                }

		# variables

                $myres = mysql_query( "show variables" );

                while ( $row = mysql_fetch_row( $myres ) ) {
                        $result[$row[0]] = $row[1];
                }

                $myres = mysql_query( "show slave status" );
                if ( $myres ) {
                        # Only on slaves.
                        while ( $row = mysql_fetch_assoc( $myres ) ) {
                                foreach ( $row as $key => $value ) {
                                        $result[$key] = $value;
                                }
                        }
                }

                mysql_close( $link );
        }

        return $result;

}

class NagiosStatus {
	var $status;
	var $message;

	function NagiosStatus() {
		$this->status = 0;
		$this->message = '';
	}

	function addStatus( $status, $message ) {
		if ( $status > $this->status ) {
			$this->status = $status;
		}
		if ( $this->message ) {
			$this->message .= "; $message";
		} else {
			$this->message = $message;
		}
	}

	function limitTest( $value, $warn, $crit, $label ) {
		if ( $value < $warn ) {
			return;
		}
		if ( $value >= $crit ) {
			$this->addStatus( 2, "$label = $value ($crit)" );
			return;
		}
		$this->addStatus( 1, "$label = $value ($crit)" );
	}

	function valueTest( $value, $expected, $label ) {
		if ( $value != $expected ) {
			$this->addStatus( 2, "$label: expected $expected, got $value" );
		}
	}

	function returnStatus() {
		switch( $this->status ) {
		case 0:
			$this->message = "OK: {$this->message}\n";
			break;
		case 1:
			$this->message = "WARNING: {$this->message}\n";
			break;
		case 2:
			$this->message = "CRITICAL: {$this->message}\n";
			break;
		}
		echo $this->message;
		exit( $this->status );
	}
}

function showHelp() {
	global $self;
	echo <<<EOT
php $self [options]
Checks the status of a MySQL server

	-h hostname	Hostname
	-u username	Username
	-p password	Password
	--slave		Tested system is a slave. Check whether replication
			is running and whether the DB is set to read only
	--rwslave	Like --slave, but read_only can be OFF
	--master	Tested system is a master. DB may not be set to read only.
			If both --master and --slave are running, the DB may not
			be set to read only.

	--warnconnected limit
			Warn if more than 'limit' threads are connected	
	--critconnected limit
			Critical if more than 'limit' threads are connected	
	--warnrunning limit
			Warn if more than 'limit' threads are running
	--critrunning limit
			Critical if more than 'limit' threads are running

	--help		Show this help message.

EOT
;
	exit( -1 );
}

#--------------
# Main
#--------------

for( $arg = reset( $argv ); $arg !== false; $arg = next( $argv ) ) {
	switch ( $arg ) {
	case '-h':
		$host = next( $argv );
		break;
	case '-u':
		$user = next( $argv );
		break;
	case '-p':
		$pass = next( $argv );
		break;
	case '--slave':
		$slave = true;
		break;
	case '--rwslave':
		$slave = $rwslave = true;
		break;
	case '--master':
		$master = true;
		break;
	case '--readonly':
		$readonly = true;
		break;
	case '--warnconnected':
		$wconnected = next( $argv );
		break;
	case '--critconnected':
		$cconnected = next( $argv );
		break;
	case '--warnrunning':
		$wrunning = next( $argv );
		break;
	case '--critrunning':
		$crunning = next( $argv );
		break;
	case '--help':
		showHelp();
		exit(-1);
	default:
		echo "Unknown option $arg\n";
		exit(3);
	}
}

$status = mysql_gather_status( $host, $user, $pass );
$n = new NagiosStatus();

if ( $status['status'] != 0 ) {
	$n->addStatus( $status['status'], $status['error'] );
	$n->returnStatus();
}

$n->limitTest( $status['Threads_running'], $wrunning, $crunning, "Running threads" );
$n->limitTest( $status['Threads_connected'], $wconnected, $cconnected, "Connected threads" );
if ( $slave ) {
	if ( isset( $status['Slave_IO_Running'] ) ) {
		$n->valueTest( $status['Slave_IO_Running'], 'Yes', "Slave running" );
	} else {
		$n->valueTest( $status['Slave_running'], 'ON', "Slave running" );
	}
	if (!$rwslave)
		$n->valueTest( $status['read_only'], 'ON', "Read only" );
} elseif ( $master ) { 
	$n->valueTest( $status['read_only'], 'OFF', "Read only" ); 
} elseif ( $readonly ) {
	if ( isset( $status['Slave_IO_Running'] ) ) {
		$n->valueTest( $status['Slave_IO_Running'], 'No', "Slave running" );
	} elseif ( isset( $status['Slave_running'] ) ) {
		$n->valueTest( $status['Slave_running'], 'OFF', "Slave running" );
	}
}
$n->returnStatus();

?>
