#
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

require "spec_helper"
require "mixlib/install"

context "Mixlib::Install::Generator" do
  let(:channel) { nil }

  let(:install_script) {
    Mixlib::Install.new(product_name: "chef",
                        channel: channel,
                        product_version: "latest").install_command
  }

  context "for :stable channel" do
    let(:channel) { :stable }

    it "outputs the install_command" do
      expect(install_script).to be_a(String)
      expect(install_script).to start_with("#!/bin/sh")
      expect(install_script).to include('install_file $filetype "$download_filename"')
    end
  end
end
