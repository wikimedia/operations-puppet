# == Class ulogd
#
# Set up and configure ulogd2
#
# == Parameters:
#[*logfile*]
#    Where to send the daemon [i.e. not the NFLOG] logs
#    options are syslog, stdout, stderr or a file path
#
#[*log_level*]
#  The logging level for ulogd logs
#
#[*logemu_logfile*]
#  file to use for LOGEM output
#
#[*oprint_logfile*]
#  file to use for OPRIN output
#
#[*gprint_logfile*]
#  file to use for GPRIN output
#
#[*xml_directory*]
#  file to use for xml files
#
#[*json_logfile*]
#  file to use for json output
#
#[*pcap_file*]
#  to use for cwlibpcap output
#
#[*config_file*]
#  location of the main config file
#
#[*syslog_facility*]
#  facility to use with syslog extension
#
#[*syslog_level*]
#  log level to use with syslog extension
#
#[*sync*]
# If true sync all disk writes to disk immediately 
#
#[*nflog*]
#  outputters to use for NFLOG
#
#[*nfct*]
#  outputters to use for NFCT
#
#[*acct*]
#  outputters to use for NACCT
#
class ulogd (
  Ulogd::Logfile       $logfile             = 'syslog',
  Ulogd::Loglevel      $log_level           = 'info',
  Stdlib::Unixpath     $logemu_logfile      = '/var/log/ulog/syslogemu.log',
  Stdlib::Unixpath     $logemu_nfct_logfile = '/var/log/ulog/syslogemu_nfct.log',
  Stdlib::Unixpath     $oprint_logfile      = '/var/log/ulog/oprint.log',
  Stdlib::Unixpath     $gprint_logfile      = '/var/log/ulog/gprint.log',
  Stdlib::Unixpath     $xml_directory       = '/var/log/ulog/',
  Stdlib::Unixpath     $json_logfile        = '/var/log/ulog/ulogd.json',
  Stdlib::Unixpath     $json_nfct_logfile   = '/var/log/ulog/ulogd_nfct.json',
  Stdlib::Unixpath     $pcap_file           = '/var/log/ulog/ulogd.pcap',
  Stdlib::Unixpath     $nacct_file          = '/var/log/ulog/nacct.log',
  Stdlib::Unixpath     $config_file         = '/etc/ulogd.conf',
  Ulogd::Facility      $syslog_facility     = 'local7',
  Ulogd::Loglevel      $syslog_level        = 'info',
  Boolean              $sync                = true,
  Array[Ulogd::Output] $nflog               = ['SYSLOG'],
  Array[Ulogd::Output] $nfct                = [],
  Array[Ulogd::Output] $acct                = [],
) {
  # An array of supported extensions that require additional packages
  # dbi, mysql, pgsql and sqlite are options for the future
  $supported_extensions = ['JSON', 'PCAP']
  require_package('ulogd2')

  $supported_extensions.each |String $extension| {
    if $extension in union($nflog, $nfct, $acct)  {
      require_package("ulogd2-${extension.downcase}")
    }
  }
  file {$config_file:
    ensure  => file,
    content => template('ulogd/etc/ulogd.conf.erb'),
    notify  => Service['ulogd2'],
  }
  service {'ulogd2':
    ensure => 'running',
    enable => true,
  }
}
