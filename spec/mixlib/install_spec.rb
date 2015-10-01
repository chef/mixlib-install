#
# Author:: Thom May (<thom@chef.io>)
# Copyright:: Copyright (c) 2015 Chef, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'spec_helper'
require 'mixlib/install/version'

describe Mixlib::Install do
  let(:install) { described_class.new('mixlib-install', '0.1.0', :stable)}

  describe '#initialize' do
    it 'sets product_name' do
      expect(install.project_name).to eq('mixlib-install')
    end

    it 'sets version' do
      expect(install.version).to eq('0.1.0')
    end

    it "sets channel" do
      expect(install.channel).to be :stable
    end
  end

  describe '#info' do
    it 'returns ArtifactInfo' do
      expect(install.info).to be_a(Mixlib::Install::ArtifactInfo)
    end
  end
end
