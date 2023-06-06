include_recipe "rack_server::_nginx_initd"

appns = node['ccbase']['application']

node[appns]['pkgs'].each do |pkg|
  package pkg do
    action :install
  end
end

nginx_site appns do
  template "default/#{appns}.conf.erb"
  variables({
    "app_name"  => appns,
    "deploy_to" => ::File.join(node['ccbase']['deploy_base'], appns)
  })
  enable true
end
