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
        begin
          service_object = CrowbarService.new(Rails.logger)

          # transition nodes to "crowbar_upgrade"
          service_object.prepare_nodes_for_crowbar_upgrade
        rescue
          flash[:alert] = t("installer.upgrades.prepare.failed")

          respond_to do |format|
            format.html do
              redirect_to prepare_upgrade_url
            end
          end
        end

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
            redirect_to root_url
          end
        end
      else
        respond_to do |format|
          format.html
        end
      end
    end

    def file
      @backup = Backup.new
      if @backup.save
        respond_to do |format|
          format.any do
            send_file(
              @backup.path,
              filename: @backup.filename
            )
          end
        end
      else
        flash[:alert] = t("installer.upgrades.backup_error")
        redirect_to download_upgrade_url
      end
    end

    def abort
      begin
        service_object = CrowbarService.new(Rails.logger)

        # revert nodes from "crowbar_upgrade"
        service_object.revert_nodes_from_crowbar_upgrade
      rescue
        flash[:alert] = t("installer.upgrades.abort.failed")
        respond_to do |format|
          format.html do
            redirect_to prepare_upgrade_url
          end
        end
      end

      respond_to do |format|
        format.html do
          redirect_to prepare_upgrade_url
        end
      end
    end

    def meta_title
      I18n.t("installer.upgrades.title")
    end
  end
end
