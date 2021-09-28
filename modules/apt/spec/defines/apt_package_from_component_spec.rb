require_relative '../../../../rake_modules/spec_helper'

describe 'apt::package_from_component' do
  on_supported_os(WMFConfig.test_on).each do |os, os_facts|
    let(:title) { 'mypackage' }
    let(:params) { { component: 'foobar' } }

    context os do
      let(:facts) { os_facts }

      context 'default parameters' do
        it { is_expected.to compile }
        it do
          is_expected.to contain_apt__repository('repository_mypackage').with(
            uri: 'http://apt.wikimedia.org/wikimedia',
            dist: "#{facts[:os]['distro']['codename']}-wikimedia",
            components: 'foobar'
          )
        end
        it { is_expected.to contain_package('mypackage').with_ensure('present') }
        it { is_expected.not_to contain_apt__pin('apt_pin_mypackage') }
      end

      context "override distro" do
        let(:params) { super().merge(distro: 'foobar') }
        it { is_expected.to compile }
        it { is_expected.to contain_apt__pin('apt_pin_mypackage') }
      end

      context "override priority" do
        let(:params) { super().merge(priority: 42) }
        it { is_expected.to compile }
        it { is_expected.to contain_apt__pin('apt_pin_mypackage') }
      end

      context "override ensure_packages" do
        let(:params) { super().merge(ensure_packages: false) }
        it { is_expected.to compile }
        it { is_expected.not_to contain_package('mypackage').with_ensure('installed') }
      end

      context "pass packages as hash" do
        let(:params) { super().merge(packages: {'foobar' => '42'}) }
        it { is_expected.to compile }
        it { is_expected.to contain_package('foobar').with_ensure('42') }
      end
    end
  end
end
