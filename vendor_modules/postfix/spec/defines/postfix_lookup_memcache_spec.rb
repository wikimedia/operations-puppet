require 'spec_helper'

describe 'postfix::lookup::memcache' do
  let(:title) do
    '/etc/postfix/test.cf'
  end

  let(:params) do
    {
      memcache: 'localhost',
    }
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end

      it { is_expected.to compile.with_all_deps }
      it { is_expected.to contain_file('/etc/postfix/test.cf') }
      it { is_expected.to contain_postfix__lookup__memcache('/etc/postfix/test.cf') }
    end
  end
end
