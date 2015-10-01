#
# Author:: Patrick Wright (<patrick@chef.io>)
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

context 'Mixlib Install' do
  let(:channel) { nil }
  let(:project){ nil }
  let(:project_version){ nil }
  let(:platform) { nil }
  let(:platform_version) { nil }
  let(:architecture) { nil }
  let(:params) do
    params = {}
    params[:v] = project_version if project_version
    params[:p] = platform if platform
    params[:pv] = platform_version if platform_version
    params[:m] = architecture if architecture
    params
  end

  # shared examples to test chef and chefdk
  # shared example per channel (stable, current)
  context 'for chef' do
    let(:project) { 'chef' }

    context 'for stable' do
      let(:channel) { 'stable' }

      context 'for mac_os_x' do
        let(:platform) { 'mac_os_x' }

        context 'for 10.7' do
          let(:platform_version) { '10.7' }

          context 'for x86_64' do
            let(:architecture) { 'x86_64' }

            context 'with a full product version' do
              let(:project_version) { '12.2.1' }
            end

            context 'with a major.minor product version' do
              let(:project_version) { '12.2' }
            end

            context 'with a major product version' do
              let(:project_version) { '12' }
            end

            context 'with latest version keyword' do
              let(:project_version) { :latest }
            end
          end
        end
      end
    end
  end
end
