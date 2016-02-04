#
# Cookbook Name:: crowbar
# Recipe:: crowbar-upgrade
#
# Copyright 2013-2015, SUSE LINUX Products GmbH
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

# Check for step in the upgrade process: if it is not 'crowbar_upgrade',
# we're returning # from previous upgrade state and need to re-enable chef-client

return unless node[:platform_family] == "suse"

upgrade_step = node["crowbar_wall"]["crowbar_upgrade_step"] || "none"
case upgrade_step
when "crowbar_upgrade"

  # Disable openstack services
  # We don't know which openstack services are enabled on the node and
  # collecting that information via the attributes provided by chef is
  # rather complicated. So instead we fall back to a simple bash hack

  bash "disable_openstack_services" do
    code <<-EOF
      for i in /etc/init.d/openstack-* \
               /etc/init.d/openvswitch-switch \
               /etc/init.d/ovs-usurp-config-* \
               /etc/init.d/drbd \
               /etc/init.d/hawk \
               /etc/init.d/openais \
               /etc/init.d/openais-shutdown;
      do
        if test -e $i
        then
          initscript=`basename $i`
          chkconfig -d $initscript
        fi
      done
    EOF
  end

  # Disable crowbar-join
  service "crowbar_join" do
    # do not stop it, it would change node's state
    action :disable
  end

  # Disable chef-client
  service "chef-client" do
    action [:disable, :stop]
  end

when "revert_to_ready"

  service "crowbar_join" do
    action :enable
  end

  service "chef-client" do
    action [:enable, :start]
  end
else
  Chef::Log.warn("Invalid upgrade step given: #{upgrade_step}")
end
