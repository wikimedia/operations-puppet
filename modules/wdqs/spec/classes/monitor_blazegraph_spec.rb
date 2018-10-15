require 'spec_helper'

describe 'icinga::monitor::wdqs', :type => :class do
  let(:facts) { { :lsbdistrelease => 'debian',
                  :lsbdistid      => 'jessie',
                  :initsystem     => 'systemd',
  } }

  it { is_expected.to contain_monitoring__graphite_threshold('wdqs-response-time-eqiad')
                          .with_metric('varnish.eqiad.backends.be_wdqs_svc_eqiad_wmnet.GET.p99')
  }
end
