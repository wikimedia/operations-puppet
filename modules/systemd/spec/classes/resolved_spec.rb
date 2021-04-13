# frozen_string_literal: true

require_relative '../../../../rake_modules/spec_helper'

describe 'systemd::resolved' do
  on_supported_os(WMFConfig.test_on(10)).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }

      describe 'test with default settings' do
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file('/etc/systemd/resolved.conf')
            .without_content(/^DNS=/)
            .without_content(/^FallbackDNS=/)
            .without_content(/^Domains=/)
            .with_content(/^LLMNR=no/)
            .with_content(/^MulticastDNS=no/)
            .with_content(/^DNSSEC=allow-downgrade/)
            .with_content(/^DNSOverTLS=no/)
            .with_content(/^Cache=yes/)
            .with_content(/^DNSStubListener=yes/)
            .with_content(/^ReadEtcHosts=yes/)
        end
      end
    end
  end
end
