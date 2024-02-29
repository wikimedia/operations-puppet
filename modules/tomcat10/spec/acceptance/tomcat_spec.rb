# SPDX-License-Identifier: Apache-2.0
# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'tomcat class' do
  describe 'running puppet code' do
    it 'work with no errors' do
      pp = "include 'tomcat'"
      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_failures: true)
      expect(apply_manifest(pp, catch_failures: true).exit_code).to eq 0
    end
    describe service('tomcat9') do
      it { is_expected.to be_enabled }
      it { is_expected.to be_running.under('systemd') }
    end
    describe port(8080) do
      it { is_expected.to be_listening }
    end
    describe command('curl http://localhost:8080') do
      its(:stdout) { is_expected.to match(%r{Apache Tomcat/9\.0\.16 \(Debian\)}) }
    end
  end
end
