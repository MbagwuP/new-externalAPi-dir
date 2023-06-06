#
# Cookbook Name:: ccbase
# Recipe:: _deployable
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

deploy_user = node['ccbase']['deploy_user']
deploy_home = ::File.join('/home', deploy_user)

group deploy_user do
  gid 501
  action :create
end.run_action(:create)

user deploy_user do
  comment "Application Deploy User"
  home deploy_home 
  shell "/bin/bash"
  system true
  supports({manage_home: true})
  uid 500
  gid 501
  action :create
end.run_action(:create)

directory ::File.join(deploy_home, '.ssh') do
  recursive true
  owner deploy_user
  group deploy_user
  mode 00750
  action :create
end.run_action(:create)

