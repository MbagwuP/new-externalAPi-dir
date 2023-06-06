property :application,        String, name_property: true
property :version,            String, required: true
property :artifact_location,  String, required: true
property :deploy_user,        String, default: "deploy"
property :deploy_group,       String, default: "deploy"
property :deploy_base,        String, default: "/var/www/html"
property :after_extract,      Proc, default: nil
property :before_deploy,      Proc, default: nil
property :after_deploy,       Proc, default: nil
property :before_symlink,     Proc, default: nil
property :should_migrate,     [TrueClass, FalseClass], default: true
property :before_migrate,     Proc,  default: nil
property :shared_directories, Array, default: %w{config}
property :config_overrides,   Hash, default: nil
property :symlinks,           Hash, default: nil
property :is_tarball,         [TrueClass, FalseClass], default: true

default_action :deploy

appns = node['ccbase']['application']
action :deploy do
  application_path = ::File.join(node['ccbase']['deploy_base'], application)
  shared_path      = ::File.join(application_path, 'shared')
  release_path     = ::File.join(application_path, 'releases', version)
  current_path     = ::File.join(application_path, 'current')
  artifact_deploy application do
    is_tarball new_resource.is_tarball
    artifact_location new_resource.artifact_location
    version new_resource.version
    deploy_to application_path
    owner deploy_user
    group deploy_group
    should_migrate new_resource.should_migrate
    shared_directories new_resource.shared_directories
    before_deploy new_resource.before_deploy

    if new_resource.after_extract
      after_extract new_resource.after_extract
    elsif !new_resource.is_tarball # Default behavior for .war files being deployed.
      after_extract Proc.new {
        execute "extract_artifact" do
          command "unzip -q -o #{::File.join(release_path, ::File.basename(new_resource.artifact_location))} -d #{release_path}/"
          user  node[appns]['deploy_user']
          group node[appns]['deploy_group']
        end

        link ::File.join(node['tomcat']['webapp_dir'], appns) do
          to current_path
          user  node[appns]['deploy_user']
          group node[appns]['deploy_group']
        end
      }
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

    if new_resource.before_migrate.nil?
      before_migrate Proc.new {
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

    symlinks new_resource.symlinks

    after_deploy new_resource.after_deploy
  end
end
