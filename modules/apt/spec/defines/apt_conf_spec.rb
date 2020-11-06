require_relative '../../../../rake_modules/spec_helper'

describe 'apt::conf' do
  # Needed to get notified by apt::conf
  let(:pre_condition) {
    'exec { "apt-get update": path => "/usr/bin" }'
  }
  on_supported_os(WMFConfig.test_on).each do |os, _facts|
    context "on #{os}" do
      let(:title) { 'myconf' }
      let(:params) do
        {
          key: "dummykey",
          value: "dummyvalue",
          priority: 1,
          ensure: "present",
        }

        it { is_expected.to compile }

        context "when passed a string as value" do
          let(:params) {
            super().merge(value: "dummyvalue")
          }
          it "the content adds quotes" do
            is_expected.to contain_file('/etc/apt/apt.conf.d/1myconf').with(
              ensure: 'present',
              owner: 'root',
              group: 'root',
              mode: '0444',
              notify: "Exec[apt-get update]"
            ).with_content("dummykey \"dummyvalue\";\n")
          end
        end

        context "when passed an int as value" do
          let(:params) {
            super().merge(value: 42)
          }
          it "the content does not add quotes" do
            is_expected.to contain_file('/etc/apt/apt.conf.d/1myconf').with(
              ensure: 'present',
              owner: 'root',
              group: 'root',
              mode: '0444',
              notify: "Exec[apt-get update]"
            ).with_content("dummykey 42;\n")
          end
        end

        context "when passed a bool as value" do
          let(:params) {
            super().merge(value: true)
          }
          it "the content adds quotes" do
            is_expected.to contain_file('/etc/apt/apt.conf.d/1myconf').with(
              ensure: 'present',
              owner: 'root',
              group: 'root',
              mode: '0444',
              notify: "Exec[apt-get update]"
            ).with_content("dummykey \"true\";\n")
          end
        end
      end
    end
  end
end
