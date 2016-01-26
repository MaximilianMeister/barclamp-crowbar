#
# Copyright 2011-2013, Dell
# Copyright 2013-2015, SUSE Linux GmbH
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

module Installer
  class UpgradesController < ApplicationController
    def prepare
      if request.post?
        respond_to do |format|
          format.html do
            redirect_to download_upgrade_url
          end
        end
      else
        respond_to do |format|
          format.html
        end
      end
    end

    def download
      if request.post?
        respond_to do |format|
          format.html do
            redirect_to confirm_upgrade_url
          end
        end
      else
        respond_to do |format|
          format.html
        end
      end
    end

    def confirm
      if request.post?
        respond_to do |format|
          format.html do
            # TODO
          end
        end
      else
        respond_to do |format|
          format.html
        end
      end
    end

    def meta_title
      I18n.t("installer.upgrades.title")
    end
  end
end
