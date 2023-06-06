module CareCloud
  module Helper
    def attribute_required(key=nil, hash={}, msg="[%s] is required!")
      hash[key] || raise(msg % key)
    end

    def convert_keys_to_symlink_hash(keys=[])
      Hash[*keys.map { |key| dirname = "config/#{key}.yml"; [dirname, dirname]}.flatten]
    end

    def sanitize_data_bag(data_bag={})
      data_bag.delete_if { |key| %{chef_type data_bag}.include?(key) }
      file_name    = data_bag.delete('id')
      file_content = wrap_with_env(remap_hash_key(data_bag))
      [file_name, file_content]
    end

    def remap_hash_key(hash={}, regex=/tmpkey_/)
      if hash.kind_of?(Hash) && hash.keys.select { |key| key =~ regex }.any?
        Hash[hash.map { |key, value| [(key.include?('tmpkey_') ? key.split('tmpkey_')[1] : key), value] }]
      else
        hash
      end
    end

    def wrap_with_env(hash={})
      wrap = hash.delete('wrap_with_env')
      if [true, 'true', nil].include?(wrap)
        {"#{node.chef_environment}" => hash, "batch" => hash}
      else
        hash
      end
    end
  end
end

Chef::Provider.send(:include, CareCloud::Helper)
