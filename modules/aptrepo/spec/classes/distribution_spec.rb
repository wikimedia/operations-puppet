require_relative '../../../../rake_modules/spec_helper'

describe 'aptrepo::distribution', :type => :class do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      let(:params) {{
        :basedir => '/srv/wikimedia',
        :settings => {
          'buster' => {
            'Suite' => 'buster-mediawiki'
          }
        },
      }}

      it { should compile }

      it do
        should contain_file('/srv/wikimedia/conf/distributions').with({
          'ensure' => 'file',
          'mode'   => '0444',
          'owner'  => 'root',
          'group'  => 'root',
        })
      end
    end
  end
end
