# SPDX-License-Identifier: Apache-2.0
require_relative "../../../../rake_modules/spec_helper"

describe "prometheus::blackbox::check::icmp", :type => :define do
  on_supported_os(WMFConfig.test_on).each do |os, os_facts|
    context "On #{os}" do
      let(:facts) { os_facts }
      let(:params) { {} }
      let(:title) { "127.0.0.1" }

      it { is_expected.to compile }
    end
  end
end
