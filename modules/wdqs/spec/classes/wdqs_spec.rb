require 'spec_helper'

describe 'wdqs', :type => :class do
  context 'using git to deploy' do
    let(:facts) { { :initsystem => 'systemd' } }

    # secret() is hard to mock, ignoring this test at the moment
    xit { is_expected.to contain_file('/etc/wdqs')
                            .with_group('deploy-service')
    }
  end

  context 'not using git to deploy' do
    let(:params) { { :use_git_deploy => false } }
    let(:facts) { { :initsystem => 'systemd' } }

    # secret() is hard to mock, ignoring this test at the moment
    xit { is_expected.to contain_file('/etc/wdqs')
                            .with_group('root')
    }
  end
end
