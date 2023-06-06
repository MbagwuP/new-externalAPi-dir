#
# Cookbook Name:: ccbase
# Recipe:: _apt
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

execute "update-package-manager" do
  command "apt-get update"
  ignore_failure true
  action :nothing
end.run_action(:run)
