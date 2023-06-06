property :remote_path,   String, required: true
property :bucket,        String, default: 'devops.shared.carecloud.com'
property :java_location, String, default: '/usr/bin/java'
property :java_home,     String, default: '/usr/lib/jvm'
property :priority,      String, default: '50000'
property :bin_cmds,      Array,  default: ['java']

default_action :set

action :set do

  # The host should use IAM roles in order to access the desired
  # AWS resource.  Should really only be used for local runs.
  # AND FOR CHRIST SAKE don't push your AWS credentials to github.
  use_aws_keys = (node['ccbase']['context']['envs'].keys &
                  %w{AWS_SECRET_KEY_ID AWS_SECRET_ACCESS_KEY}).length == 2

  repo_path = remote_path.split('/')
  version, package = repo_path[repo_path.length-2..-1]
  s3_file ::File.join(Chef::Config['file_cache_path'], package) do
    bucket new_resource.bucket
    remote_path new_resource.remote_path
    owner 'root'
    group 'root'
    mode 00744
    action :create

    if use_aws_keys
      aws_access_key_id node['ccbase']['context']['envs']['AWS_SECRET_KEY_ID']
      aws_secret_access_key node['ccbase']['context']['envs']['AWS_SECRET_ACCESS_KEY']
    end
  end.run_action(:create)

  execute 'extract_jdk_to_dir' do
    command <<-EOF
    mkdir -p #{java_home}
    tar -xzvf #{package} -C #{java_home}
    EOF
    cwd Chef::Config['file_cache_path']
    user  'root'
    group 'root'
    action :nothing
    not_if { ::File.exists? ::File.join(java_home, version) }
  end.run_action(:run)

  bin_cmds.each do |cmd|
    execute 'set_java_version' do
      command <<-EOF
      update-alternatives --install #{java_location} #{cmd} #{java_home}/#{version}/bin/#{cmd} #{priority}
      echo 1 | update-alternatives --config #{cmd}
      EOF
      user 'root'
      group 'root'
      action :nothing
    end.run_action(:run)
  end

  node.set['java']['java_home'] = ::File.join(java_home, version)
end
