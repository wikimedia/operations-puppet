# SPDX-License-Identifier: Apache-2.0
# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'apereo_cas class' do
  describe 'running puppet code' do
    it 'work with no errors' do
      pp = "class {'apereo_cas': keystore_source => 'puppet:///modules/apereo_cas/thekeystore' }"
      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_failures: true)
      expect(apply_manifest(pp, catch_failures: true).exit_code).to eq 0
    end
    describe service('cas') do
      it { is_expected.to be_enabled }
      it { is_expected.to be_running.under('systemd') }
    end
    describe port(8443) do
      let(:pre_command) { 'sleep 30' }
      it { is_expected.to be_listening }
    end
    describe command('curl -k https://localhost:8443/cas/login') do
      its(:stdout) { is_expected.to match(/Login - CAS &#8211; Central Authentication Service/) }
    end
  end
end
