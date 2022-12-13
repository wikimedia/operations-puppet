require 'spec_helper'

describe 'postfix' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end

      it { is_expected.to compile.with_all_deps }
      it { is_expected.to contain_augeas__lens('postfix_master') }
      it { is_expected.to contain_class('postfix') }
      it { is_expected.to contain_class('postfix::config') }
      it { is_expected.to contain_class('postfix::install') }
      it { is_expected.to contain_class('postfix::service') }
      it { is_expected.to contain_file('/etc/postfix/main.cf') }
      it { is_expected.to contain_file('/etc/postfix/master.cf') }
      it { is_expected.to contain_package('postfix') }

      it { is_expected.to contain_postfix_main('alias_database') }
      it { is_expected.to contain_postfix_main('alias_maps') }
      it { is_expected.to contain_postfix_main('command_directory') }
      it { is_expected.to contain_postfix_main('daemon_directory') }
      it { is_expected.to contain_postfix_main('data_directory') }
      it { is_expected.to contain_postfix_main('debug_peer_level') }
      it { is_expected.to contain_postfix_main('debugger_command') }
      it { is_expected.to contain_postfix_main('default_database_type') }
      it { is_expected.to contain_postfix_main('html_directory') }
      it { is_expected.to contain_postfix_main('inet_interfaces') }
      it { is_expected.to contain_postfix_main('inet_protocols') }
      it { is_expected.to contain_postfix_main('mail_owner') }
      it { is_expected.to contain_postfix_main('mailq_path') }
      it { is_expected.to contain_postfix_main('manpage_directory') }
      it { is_expected.to contain_postfix_main('mydestination') }
      it { is_expected.to contain_postfix_main('newaliases_path') }
      it { is_expected.to contain_postfix_main('queue_directory') }
      it { is_expected.to contain_postfix_main('readme_directory') }
      it { is_expected.to contain_postfix_main('sample_directory') }
      it { is_expected.to contain_postfix_main('sendmail_path') }
      it { is_expected.to contain_postfix_main('setgid_group') }
      it { is_expected.to contain_postfix_main('unknown_local_recipient_reject_code') }
      it { is_expected.to contain_postfix_master('anvil/unix') }
      it { is_expected.to contain_postfix_master('bounce/unix') }
      it { is_expected.to contain_postfix_master('cleanup/unix') }
      it { is_expected.to contain_postfix_master('defer/unix') }
      it { is_expected.to contain_postfix_master('discard/unix') }
      it { is_expected.to contain_postfix_master('error/unix') }
      it { is_expected.to contain_postfix_master('flush/unix') }
      it { is_expected.to contain_postfix_master('lmtp/unix') }
      it { is_expected.to contain_postfix_master('local/unix') }
      it { is_expected.to contain_postfix_master('proxymap/unix') }
      it { is_expected.to contain_postfix_master('proxywrite/unix') }
      it { is_expected.to contain_postfix_master('relay/unix') }
      it { is_expected.to contain_postfix_master('retry/unix') }
      it { is_expected.to contain_postfix_master('rewrite/unix') }
      it { is_expected.to contain_postfix_master('scache/unix') }
      it { is_expected.to contain_postfix_master('showq/unix') }
      it { is_expected.to contain_postfix_master('smtp/inet') }
      it { is_expected.to contain_postfix_master('smtp/unix') }
      it { is_expected.to contain_postfix_master('tlsmgr/unix') }
      it { is_expected.to contain_postfix_master('trace/unix') }
      it { is_expected.to contain_postfix_master('verify/unix') }
      it { is_expected.to contain_postfix_master('virtual/unix') }

      it { is_expected.to contain_resources('postfix_main') }
      it { is_expected.to contain_resources('postfix_master') }
      it { is_expected.to contain_service('postfix') }

      case facts[:os]['family']
      when 'RedHat'
        if facts[:os]['release']['major'].eql?('6')
          it { is_expected.to contain_postfix_master('pickup/fifo') }
          it { is_expected.to contain_postfix_master('qmgr/fifo') }
        else
          it { is_expected.to contain_postfix_master('pickup/unix') }
          it { is_expected.to contain_postfix_master('qmgr/unix') }
        end

        if facts[:os]['release']['major'].eql?('8')
          it { is_expected.to contain_postfix_main('compatibility_level') }
          it { is_expected.to contain_postfix_main('meta_directory') }
          it { is_expected.to contain_postfix_main('shlib_directory') }
          it { is_expected.to contain_postfix_main('smtp_tls_CAfile') }
          it { is_expected.to contain_postfix_main('smtp_tls_CApath') }
          it { is_expected.to contain_postfix_main('smtp_tls_security_level') }
          it { is_expected.to contain_postfix_main('smtpd_tls_cert_file') }
          it { is_expected.to contain_postfix_main('smtpd_tls_key_file') }
          it { is_expected.to contain_postfix_main('smtpd_tls_security_level') }
          it { is_expected.to contain_postfix_master('postlog/unix-dgram') }
        end
      end
    end
  end
end
