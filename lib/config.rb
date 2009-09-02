class Trufina
  class Config
    cattr_accessor  :credentials, :staging_access, :endpoints,
                    :app_root, :config_file, :mode
    
    # Allow range of config locations
    self.app_root          = RAILS_ROOT if defined?(RAILS_ROOT)
    self.app_root          = Merb.root  if defined?(Merb)
    self.app_root        ||= app_root
    self.app_root        ||= Dir.pwd
    self.config_file       = File.join(self.app_root, 'config', 'trufina.yml')

    # Symbolize hash keys - defined here so we don't rely on Rails
    def self.symbolize_keys!(hash)
      return hash unless hash.is_a?(Hash)
      
      hash.keys.each do |key|
        unless key.is_a?(Symbol)
          hash[key.to_sym] = hash[key]
          hash.delete(key)
        end
      end
      hash
    end

    # Ensure config exists
    unless File.exists?(self.config_file)
      config_template = File.join(File.dirname(__FILE__), '..', 'trufina.yml.template')
      File.copy(config_template, self.config_file)
      raise ConfigFileError.new("Unable to create configuration template at #{self.config_file}") unless File.exists?(self.config_file)
    end
    
    # Load keys from config file into the class
    YAML.load(ERB.new(File.read(self.config_file)).result).each do |key, value|
      self.send("#{key}=", symbolize_keys!(value)) if self.methods.include?("#{key}=")
    end
    
    # Set default mode unless already set in the config file
    unless %w(production staging).include?(self.mode)
      env = defined?(Merb) ? ENV['MERB_ENV'] : ENV['RAILS_ENV']
      @@mode = env && env == 'production' ? 'production' : 'staging'
    end
    
    # Ensure template file has been modified with (hopefully) real data
    if self.credentials.any?{|k,v| v == 'YOUR_DATA_HERE'}
      raise ConfigFileError.new("Don't forget to update the Trufina config file with your own data! File is located at #{self.config_file}")
    end
    
    
    
    # Syntactic sugar for setting and checking the current operating mode
    class << self
      %w(staging production).each do |mode|
        define_method("#{mode}!"){ @@mode = mode }
        define_method("#{mode}?"){ @@mode == mode }
      end
    end
    
  end
end