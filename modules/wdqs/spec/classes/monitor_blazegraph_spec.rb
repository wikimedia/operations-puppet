require 'spec_helper'

describe 'wdqs::monitor::blazegraph', :type => :class do
  let(:facts) { { :lsbdistrelease => 'debian',
                  :lsbdistid      => 'jessie',
                  :initsystem     => 'systemd',
                  :fqdn           => 'my.example.net',
  } }

  it { is_expected.to contain_monitoring__graphite_threshold('wdqs-response-time')
                          .with_metric('varnish.eqiad.backends.be_my_example_net.GET.p99')
  }
end
