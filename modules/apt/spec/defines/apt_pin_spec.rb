require 'spec_helper'

describe 'apt::pin' do
  let(:pre_condition) {
    'exec { "apt-get update": path => "/usr/bin" }
     exec { "foobar": command => "/bin/true" }'
  }
  let(:params) { {
    :pin => 'release o=Wikimedia',
    :priority => '1042',
  } }

  context do
    let(:title) { 'mypackage' }
    it { should compile }
    it "have file with correct content and dependencies" do
      is_expected.to contain_file('/etc/apt/preferences.d/mypackage.pref').with(
        ensure: 'present',
        owner: 'root',
        group: 'root',
        mode: '0444',
        notify: "Exec[apt-get update]"
      ).with_content(
        /Package:\smypackage\n
        Pin:\srelease\so=Wikimedia\n
        Pin-Priority:\s1042\n/x
      )
    end
  end

  context "override parameters" do
    let(:title) { 'mypackage' }
    before(:each) { params.merge!(notify: ref('Exec', 'foobar')) }
    it { should compile }
    it "has no file notify" do
      is_expected.to contain_file(
        '/etc/apt/preferences.d/mypackage.pref'
      ).with_notify('Exec[foobar]')
    end
  end
  context "when title has spaces" do
    let(:title) { 'pin package' }
    it "convert spaces to underscores" do
      is_expected.to contain_file('/etc/apt/preferences.d/pin_package.pref')
    end
  end

  context "when title already has '.pref'" do
    let(:title) { 'mypackage.pref' }
    it { should compile }
    it "accept name with pref" do
      is_expected.to contain_file('/etc/apt/preferences.d/mypackage.pref')
    end
  end
end
