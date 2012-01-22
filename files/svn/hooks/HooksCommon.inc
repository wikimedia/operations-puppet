<?php

##################################
# THIS FILE IS MANAGED BY PUPPET #
##################################

/**
 * Utility class for things relating to commits and their tests.
 */
class CommitInfo {
	/**
	 * Subversion repository path
	 * @var string
	 */
	protected $repo;

	/**
	 * Transaction number
	 * @var int
	 */
	protected $transaction;

	/**
	 * Location of svnlook, in case it's not in $PATH
	 * @var string
	 */
	protected $svnlook = '/usr/bin/svnlook';

	/**
	 * Location of PHP binary, in case it's not in $PATH
	 * @var string
	 */
	protected $php = '/usr/bin/php';

	/**
	 * Tests to run, with their configuration
	 * @var array
	 */
	protected $preCommitTests = array(
		'testLogMessageLength' => array(
			1, /** min length **/
			'[a-z0-9]+' /** regex to check **/
		),
		'testPHPLint' => array(
			array( 'php', 'php5', 'phtml', 'inc' ), /** valid types to check **/
		),
		'testBadUsers' => array(
			array( 'root' ), /** users we don't want commits from **/
		),
	);

	/**
	 * Places to ping after a commit has completed (CR, CI, etc)
	 * @var array
	 */
	protected $postCommitPings = array(
		'notifyMailingList' => array(
			'mediawiki-cvs@lists.wikimedia.org', /** list **/
			'smtp.pmtpa.wikimedia.org', /** smtp host **/
		),
		'notifyIRCBot' => array(
			'cia_bot.py', /** name of the notifier script **/
			'mediawiki', /** account name with cia.vc **/
		),
		'pingURL' => array(
			'http://www.mediawiki.org/w/api.php?action=codeupdate&format=xml&repo=MediaWiki&rev=$REV',
		),
		'pingJenkins' => array(
			'http://ci2.tesla.usability.wikimedia.org:8080/subversion/$UUID/notifyCommit?rev=$REV',
		),
	);

	/**
	 * Class constructor
	 *
	 * @param $repo String name of repository
	 * @param $txn String on pre-commit, this is a pending transaction, on
	 * post-commit, this refers to the committed revision.
	 */
	public function __construct( $repo, $txn ) {
		$this->repo = $repo;
		$this->transaction = $txn;
	}

	/**
	 * Run SVN pre-commit tests
	 *
	 * @return int
	 */
	public function runPreCommitTests() {
		$result = 0;
		$messages = '';
		foreach( $this->preCommitTests as $test => $params ) {
			$msg = call_user_func_array( array( $this, $test ), $params );
			if( $msg !== true ) {
				$messages .= "$msg\n";
				$result++;
			}
		}
		if ( $result ) {
			$messages = rtrim( $messages );
			fwrite( STDERR, "----------------\n$messages\n----------------" );
		}
		return $result;
	}

	/**
	 * Run SVN post-commit pings
	 *
	 * @return int
	 */
	public function runPostCommitPings() {
		foreach( $this->postCommitPings as $ping => $params ) {
			call_user_func_array( array( $this, $ping ), $params );
		}
		return 0;
	}

	/**
	 * Get commit log message
	 *
	 * @return string
	 */
	protected function getLogMessage() {
		$output = null;
		$cmd = "{$this->svnlook} log -t '{$this->transaction}' '{$this->repo}'";
		exec( $cmd, $output );
		return implode( $output );
	}

	/**
	 * Get commit author
	 *
	 * @return string
	 */
	protected function getAuthor() {
		$output = null;
		$cmd = "{$this->svnlook} author -t '{$this->transaction}' '{$this->repo}'";
		exec( $cmd, $output );
		return trim( implode( $output ) );
	}

	/**
	 * Get commit files list
	 *
	 * @return array filenames are keys and status letters are values
	 */
	protected function getCommitList() {
		$output = null;
		$cmd = "{$this->svnlook} changed -t '{$this->transaction}' '{$this->repo}'";
		exec( $cmd, $output );

		$list = array();
		foreach( $output as $item ) {
			$pos = strpos( $item, ' ' );
			$status = substr( $item, 0, $pos );
			$file = trim( substr( $item, $pos ) );
			$list[$file] = $status;
		}
		return $list;
	}

	/**
	 * Get array of modified and added files
	 *
	 * @param $fileTypes array of file types used for filtering
	 * @return array
	 */
	protected function getChangedFiles( array $fileTypes = array() ) {
		$list = $this->getCommitList();
		$files = array();
		foreach ( $list as $file => $status ) {
			if ( 'D' == $status || substr( $file, -1 ) == DIRECTORY_SEPARATOR ) {
				continue;
			}
			$files[] = $file;
		}

		$matchingChangedFiles = array();
		foreach( $files as $file ) {
			$extension = strtolower( pathinfo( $file, PATHINFO_EXTENSION ) );
			if ( $fileTypes && !in_array( $extension, $fileTypes ) ) {
				continue;
			}
			$matchingChangedFiles[$file] = $extension;
		}
		return $matchingChangedFiles;
	}

	/**
	 * Get the repository UUID
	 *
	 * @return String
	 */
	protected function getRepoUUID() {
		$output = null;
		$cmd = "{$this->svnlook} uuid '{$this->repo}'";
		exec( $cmd, $output );
		return trim( implode( $output ) );
	}

	/**
	 * Check if log message validates length rules
	 *
	 * @param $minLength int minimum length of log message
	 * @param $regex string
	 *
	 * @return bool
	 */
	protected function testLogMessageLength( $minLength = 1, $regex = '' ) {
		$msg = trim( $this->getLogMessage() );
		$length = strlen( $msg );
		if ( $length < $minLength ) {
			if ( $minLength <= 1 ) {
				return "Log message should not be empty. Please specify descriptive log message.";
			} else {
				return "You log message is too short ($length). It should be at least $minLength characters long.";
			}
		} elseif( !preg_match( "/$regex/i", $msg ) ) {
			return "Please provide a descriptive commit message with letters.";
		}
		return true;
	}

	/**
	 * Check if PHP-related files pass a basic lint test
	 *
	 * @param $fileTypes array
	 * @return bool|string
	 */
	protected function testPHPLint( $fileTypes ) {
		$output = null;
		$result = '';
		$changedFiles = $this->getChangedFiles( $fileTypes );
		foreach( $changedFiles as $file => $ext ) {
			$cmd = "{$this->php} -l $file";
			exec( $cmd, $output );
			foreach( $output as $item ) {
				if( strpos( trim( $item ), 'No syntax errors detected in' ) === false ) {
					$result .= "$item\n";
				}
			}
		}
		return $result !== '' ? $result : true;
	}

	/**
	 * Some users we don't like committing as (eg: root). Bail and yell at them.
	 *
	 * @param $badUsers array of bad user names
	 * @return bool|string
	 */
	protected function testBadUsers( $badUsers ) {
		$ourUser = $this->getAuthor();
		if( in_array( $ourUser, $badUsers ) ) {
			return "Please do not commit as '{$ourUser}', use your real commit name";
		}
		return true;
	}

	/**
	 * Use svnnotify to notify a mailing list about the commit
	 * @param $list String Name of the list
	 * @param $smtp String SMTP host to use
	 * @todo Make the CR header less hardcoded
	 */
	protected function notifyMailingList( $list, $smtp, $header = '' ) {
		$cmd = "{$this->svnnotify} --repos-path \"{$this->repo}\" --revision \"{$this->transaction}\""
			. " --to \"{$list}\" --smtp {$smtp} --subject-prefix \"SVN: \""
			. " --subject-cx --no-first-line --with-diff --user-domain \"svn.wikimedia.org\""
			. " --header \"http://www.mediawiki.org/wiki/Special:Code/MediaWiki/{$this->transaction}\""
			. " -l {$this->svnlook}";
	}

	/**
	 * Notify a cia-esque bot about the commit
	 * @param $ciaScript String Name of the bot script
	 * @param $acctName String Name of the account with cia.vc
	 */
	protected function notifyIRCBot( $ciaScript, $acctName ) {
		exec( "{$ciaScript} \"{$this->repo}\" \"{$this->transaction}\" \"{$acctName}\"" );
	}

	/**
	 * Jenkins needs a little more info than a normal ping. So append post data.
	 */
	protected function pingJenkins( $url ) {
		$output = null;
		exec( "{$this->svnlook} changed --revision {$this->transaction} {$this->repo}", $output );
		$this->pingUrl( $url, implode( "\n", $output ) );
	}

	/**
	 * Submit a POST request to the given URL
	 * @param $url String A url to submit revision info to $REV will be replaced
	 * with the revision number, and $UUID will become the repo unique identifier
	 */
	protected function pingURL( $url, $postData = '' ) {
		$url = str_replace( array( '$REV', '$UUID' ),
			array( $this->transaction, $this->getRepoUUID() ), $url );
		$ch = curl_init();
		curl_setopt( $ch, CURLOPT_URL,$url );
		curl_setopt( $ch, CURLOPT_POST, true );
		curl_setopt( $ch, CURLOPT_POSTFIELDS, $postData );
		curl_setopt( $ch, CURLOPT_USERAGENT, 'post-commit-cr-hook/0.1' );
		curl_exec( $ch );
		curl_close( $ch );
	}
}
