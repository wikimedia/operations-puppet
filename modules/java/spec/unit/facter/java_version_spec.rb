# SPDX-License-Identifier: Apache-2.0
# require_relative '../../../../../rake_modules/spec_helper'
#
# tests = {
#   'opnjdk7' => {
#     'java_version' => '1.7.0_71',
#     'java' => { 'version' => {'full' => '1.7.0_71', 'major' => 7}},
#     'output' => <<-JDK7
# openjdk version "1.7.0_71"
# OpenJDK Runtime Environment (build 1.7.0_71-b14)
# OpenJDK 64-Bit Server VM (build 24.71-b01, mixed mode)
# JDK7
#   },
#   'opnjdk8' => {
#     'java_version' => '1.8.0_265',
#     'java' => { 'version' => {'full' => '1.8.0_265', 'major' => 8}},
#     'output' => <<-JDK8
# openjdk version "1.8.0_265"
# OpenJDK Runtime Environment (build 1.8.0_265-8u265-b01-0+deb9u1-b01)
# OpenJDK 64-Bit Server VM (build 25.265-b01, mixed mode
# JDK8
#   },
#   'opnjdk11' => {
#     'java_version' => '11.0.9',
#     'java' => { 'version' => {'full' => '11.0.9', 'major' => 11}},
#     'output' => <<-JDK11
# openjdk version "11.0.9" 2020-10-20
# OpenJDK Runtime Environment (build 11.0.9+11-post-Debian-1deb10u1)
# OpenJDK 64-Bit Server VM (build 11.0.9+11-post-Debian-1deb10u1, mixed mode, sharing)
# JDK11
#   },
# }
#
# describe 'java_version' do
#   before(:each) do
#     Facter.clear
#   end
#   let(:facts) { { kernel: 'Linux' } }
#
#   context 'when java present, returns java version' do
#     before(:each) do
#       expect(Facter::Util::Resolution).to receive(:which).with('java').and_return('/path/to/java')
#     end
#     tests.each_pair do |test, config|
#       context "when #{test}" do
#         before(:each) do
#           expect(Facter::Util::Resolution).to receive(:exec).with('java -Xmx12m -version 2>&1').and_return(config['output'])
#         end
#         context 'when Legacy fact' do
#           it { expect(Facter.value(:java_version)).to eq(config['java_version']) }
#         end
#         context 'when complex fact' do
#           it { expect(Facter.value(:java)).to eq(config['java']) }
#         end
#       end
#     end
#   end
#   context 'when java not present, returns nil' do
#     it do
#       expect(Facter::Util::Resolution).to receive(:which).at_least(1).with('java').and_return(false)
#       expect(Facter.value(:java_version)).to be_nil
#     end
#   end
# end
