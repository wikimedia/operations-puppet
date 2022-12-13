require 'spec_helper'

describe 'postfix::lookup::sqlite' do
  let(:title) do
    '/etc/postfix/test.cf'
  end

  let(:params) do
    {
      dbpath: '/path/to/database',
      query:  "SELECT address FROM aliases WHERE alias = '%s'",
    }
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end

      it { is_expected.to compile.with_all_deps }
      it { is_expected.to contain_file('/etc/postfix/test.cf') }
      it { is_expected.to contain_postfix__lookup__sqlite('/etc/postfix/test.cf') }
    end
  end
end
