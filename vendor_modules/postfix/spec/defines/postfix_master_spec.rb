require 'spec_helper'

describe 'postfix::master' do
  let(:title) do
    'submission/inet'
  end

  let(:params) do
    {
      command: 'smtpd',
      private: 'n',
      chroot:  'n',
    }
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end

      it { is_expected.to compile.with_all_deps }
      it { is_expected.to contain_postfix_master('submission/inet') }
      it { is_expected.to contain_postfix__master('submission/inet') }
    end
  end
end
