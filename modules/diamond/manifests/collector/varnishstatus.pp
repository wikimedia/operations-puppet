# == Define: diamond::collector::nginx
#
# configures the Diamond VarnishStatusCollector to poll it varnish stats.

define diamond::collector::varnishstatus {
  diamond::collector { 'VarnishStatus':
    source  => 'puppet:///modules/diamond/collector/varnishstatus.py',
    settings => {
      path => $domain
    }
  }
}
