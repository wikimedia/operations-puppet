require_relative '../../../../rake_modules/spec_helper'

describe 'install_server::web_server', :type => :class do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "On #{os}" do
      let(:facts){ facts }

      it { is_expected.to compile }
      it do
          is_expected.to contain_file('/srv/index.html').with({
              'mode'    => '0444',
              'owner'   => 'root',
              'group'   => 'root',
              'content' => '',
          })
      end
    end
  end
end
