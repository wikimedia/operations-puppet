require_relative '../../../../rake_modules/spec_helper'

describe 'systemd::environment' do
  on_supported_os(WMFConfig.test_on).each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:title) { 'dummy'}
      let(:params) {{ variables: {'FOO' => 'foo', 'BAR' => 'bar'}}}

      context 'when using defaults' do
        it do is_expected.to contain_file('/etc/environment.d/50-dummy.conf')
          .with_ensure('file')
          .with_content("FOO=\"foo\"\nBAR=\"bar\"\n")
        end
      end
    end
  end
end
