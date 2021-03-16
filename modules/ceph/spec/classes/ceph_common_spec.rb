require_relative '../../../../rake_modules/spec_helper'

describe 'ceph::common' do
  on_supported_os(WMFConfig.test_on(10, 10)).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      let(:params) do
        {
          home_dir: '/home/cephuser',
        }
      end
      describe 'compiles without errors' do
        it { is_expected.to compile.with_all_deps }
      end
    end
  end
end
