require 'spec_helper'

describe 'wdqs::service', :type => :class do
  context 'with systemd' do
    let(:facts) { { :initsystem => 'systemd' } }

    it { is_expected.to contain_file('/lib/systemd/system/wdqs-blazegraph.service')
      .with_content(/runBlazegraph.sh -f RWStore.properties/)
    }
  end

  context 'with upstart' do
    let(:facts) { { :initsystem => 'upstart' } }

    it { is_expected.to contain_file('/etc/init/wdqs-blazegraph.conf')
                            .with_content(/runBlazegraph.sh -f RWStore.properties/)
    }
  end
end
