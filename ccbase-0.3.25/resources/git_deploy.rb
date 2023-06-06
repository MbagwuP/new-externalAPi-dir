property :application,                String, name_property: true
property :git_profile,                String, default: "CareCloud"
property :deploy_user,                String, default: "deploy"
property :deploy_base,                String, default: "/var/www/html"
property :branch,                     String, default: "develop"
property :before_symlink,             Proc,   default: nil
property :before_migrate,             Proc,   default: nil
property :before_restart,             Proc,   default: nil
property :after_deploy,               Proc,   default: nil
property :symlinks,                   Hash,   default: {}
property :deploy_key_source,          String, default: "ccbase"
property :config_overrides,           Hash,   default: nil
property :restart_command,            [Proc, String], default: nil
property :create_dirs_before_symlink, Array,  default: []
property :symlink_before_migrate,     Hash,   default: {}

default_action :deploy

appns = node['ccbase']['application']
action :deploy do
  directory "/tmp/private_code/.ssh" do
    owner deploy_user
    recursive true
  end

  cookbook_file "/tmp/private_code/.ssh/id_deploy" do
    source "id_deploy"
    cookbook deploy_key_source
    owner deploy_user
    mode 00600
  end

  cookbook_file "/tmp/private_code/wrap-ssh4git.sh" do
    source "wrap-ssh4git.sh"
    cookbook "ccbase"
    owner deploy_user
    mode 00755
  end

  directory deploy_base do
    owner deploy_user
    recursive true
  end

  application_path = ::File.join(node['ccbase']['deploy_base'], application)
  shared_path      = ::File.join(application_path, 'shared')
  deploy application_path do
    provider Chef::Provider::Deploy::Revision
    repo "git@github.com:#{git_profile}/#{application}.git"
    branch new_resource.branch
    user deploy_user
    keep_releases 3
    shallow_clone true
    ssh_wrapper "/tmp/private_code/wrap-ssh4git.sh"

    if new_resource.before_migrate.nil?
      before_migrate Proc.new {
        node[appns]['shared_dirs'].each do |dir|
          directory ::File.join(shared_path, dir) do
            recursive true
            user node['ccbase']['deploy_user']
          end
        end
        execute "bundle install --deployment --path #{shared_path}/vendor_bundle --binstubs" do
          user  node[appns]['deploy_user']
          group node[appns]['deploy_group']
          cwd release_path
          only_if { node['ccbase']['bundle'] == true }
        end
      }
    else
      before_migrate new_resource.before_migrate
    end

    # before_symlink before_configure unless before_configure.nil?
    if new_resource.before_symlink.nil?
      before_symlink Proc.new {
        node[appns]['purge_files_before_symlink'].each do |file_name|
          execute "Removing #{file_name}" do
            command "rm -rf #{file_name}"
            cwd release_path
            only_if { ::File.directory?("#{release_path}/#{file_name}") || ::File.exists?("#{release_path}/#{file_name}") }
          end
        end

        # Generate configurations in the shared directory
        node[appns]['configs'].each do |data_bag_item|
          config = Chef::DataBagItem.load(node[appns]['configs_databag'], data_bag_item).to_hash
          if new_resource.config_overrides && new_resource.config_overrides.keys.include?(config["id"])
            config = Chef::Mixin::DeepMerge.deep_merge(new_resource.config_overrides[config["id"]], config)
          end
          file_name, file_content = sanitize_data_bag(config)
          template ::File.join(shared_path, 'config', "#{file_name}.yml") do
            source "abstract.yml.erb"
            cookbook "ccbase"
            user  node[appns]['deploy_user']
            group node[appns]['deploy_group']
            variables data: file_content
          end
        end
      }
    else
      before_symlink new_resource.before_symlink
    end

    symlinks new_resource.symlinks

    before_restart new_resource.before_restart

    restart_command new_resource.restart_command

    create_dirs_before_symlink new_resource.create_dirs_before_symlink

    symlink_before_migrate new_resource.symlink_before_migrate

    after_deploy new_resource.after_deploy
  end
end
