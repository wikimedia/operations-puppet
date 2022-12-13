require 'spec_helper'

describe 'postfix::lookup::pgsql' do
  let(:title) do
    '/etc/postfix/test.cf'
  end

  let(:params) do
    {
      hosts:    ['localhost'],
      user:     'user',
      password: 'password',
      dbname:   'database',
      query:    "SELECT address FROM aliases WHERE alias = '%s'",
    }
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end

      it { is_expected.to compile.with_all_deps }
      it { is_expected.to contain_file('/etc/postfix/test.cf') }
      it { is_expected.to contain_postfix__lookup__pgsql('/etc/postfix/test.cf') }
    end
  end
end
