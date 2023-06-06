#
# Cookbook Name:: ccbase
# Recipe:: setup
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

# NOTE: Force chef run to work under 022 context.
::File.umask(022)

include_recipe "ccbase::_apt"
include_recipe "ccbase::_timezone"
include_recipe "ccbase::_motd_tail"
include_recipe "ccbase::_deployable"
include_recipe "ccbase::_setenv"

#if node['virtualization']['system'] != "docker"
#  include_recipe "cc_filebeat::default"
#end

# NOTE: Force file system to work under 022 context.
ruby_block 'override_umask' do
  block do
    bashrc = Chef::Util::FileEdit.new('/etc/bash.bashrc')
    bashrc.insert_line_if_no_match(/umask \d{3}/, 'umask 022')
    bashrc.write_file
  end
end.run_action(:run)

bash 'source_bashrc' do
  user 'root'
  code "source /etc/bash.bashrc"
end.run_action(:run)

if ::File.exists?("/etc/profile.d/environment.sh")
  ruby_block "setup application environment variables" do
    block do
      ::File.open("/etc/profile.d/environment.sh", "r") do |file|
        file.read.split("\n").each do |envs|
          envars = envs.split("=")
          ENV[envars[0]] = envars[1]
        end
      end
    end
  end
end

# NOTE: Poor mans UFW manipulator.
if node.attribute?('ufw_access') && node['ufw_access']['rules'].any?
  if node['ufw_access']['pkg_install']
    package 'ufw'
    execute 'ufw allow proto tcp from any to any port 22'
    execute 'yes | ufw enable'
  end

  node['ufw_access']['rules'].each do |rule| 
    execute rule do
      command rule
      user 'root'
    end
  end
end
