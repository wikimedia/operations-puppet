require_relative '../../../../rake_modules/spec_helper'

describe 'cassandra', :type => :class do
    on_supported_os(WMFConfig.test_on).each do |os, facts|
        context "on #{os}" do
          let(:params) {  {target_version: '3.x'} }
          let(:facts) { facts }

          # check that there are no dependency cycles
          it { is_expected.to compile }

          it { is_expected.to contain_package('cassandra') }
        end
    end
end
