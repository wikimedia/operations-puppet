require 'spec_helper'

describe 'apt::pin' do
    let(:pre_condition) {
        'exec { "apt-get update": path => "/usr/bin" }'
    }
    let(:params) { {
        :pin => 'release o=Wikimedia',
        :priority => '1042',
    } }

    context do
        let(:title) { 'mypackage' }
        it { should compile }
    end

    context "when title has spaces" do
        let(:title) { 'pin package' }
        it "convert spaces to underscores" do
            is_expected.to contain_file('/etc/apt/preferences.d/pin_package.pref')
        end
    end

    context "when title already has '.pref'" do
        let(:title) { 'mypackage.pref' }
        it { should compile.and_raise_error(/must not have a "\.pref" suffix/) }
    end
end
