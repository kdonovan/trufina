class Object # http://whytheluckystiff.net/articles/seeingMetaclassesClearly.html
  def meta_def name, &blk
    (class << self; self; end).instance_eval { define_method name, &blk }
  end
end

class Trufina
  class Config
    # Helper method for reading in config data
    def self.recursively_symbolize_keys!(hash)
      hash.symbolize_keys!
      hash.values.select{|v| v.is_a? Hash}.each{|h| recursively_symbolize_keys!(h)}
    end
    
    
    # Now actually read in the configuration file
    begin
      @@config_path = File.join(RAILS_ROOT, 'config', 'trufina.yml')
      @@config = YAML.load(ERB.new(File.read(@@config_path)).result)
    rescue
      raise ConfigFileNotFoundError.new("No config at #{@@config_path}")
    end
    recursively_symbolize_keys!(@@config)
    cattr_reader :config

    # Allow e.g. Trufina::Config.credentials
    @@config.keys.each do |k|
      meta_def k do
        @@config[k]
      end
    end

  end
  
  
  
  # Handle creating a HappyMapper object from Array or hash
  module AllowCreationFromHash
    
    def initialize(seed_data = {})
      seed_data.is_a?(Array) ? create_empty_nodes(seed_data) : create_nodes(seed_data)
    end

    protected
    
    # e.g. Trufina::Name.new([:first, :suffix]) - no values provided, print empty nodes
    #
    #     <Name>
    #       <First/>
    #       <Suffix/>
    #     </Name>
    def create_empty_nodes(nodes)
      nodes.each do |node|
        create_node(node)
      end
    end

    # e.g. Trufina::Name.new({:first => 'Bob', :suffix => 'III'}) - print nodes with values
    # 
    #     <Name>
    #       <First>Bob</First>
    #       <Suffix>III</Suffix>
    #     </Name>
    def create_nodes(nodes)
      nodes.each do |node, content|
        create_node(node, content)
      end
    end
    
    def create_node(name, content = nil)
      case name
      when Array then create_empty_nodes(name)
      when Hash then create_nodes(name)
      else
        unless element = self.class.elements.detect{|e| e.method_name.to_sym == name}
          raise InvalidElement.new("Unknown element '#{name}'")
        end
        
        value = if HappyMapper::Item::Types.include?(element.type)
          content ? content : ''
        else 
          content ? element.type.new(content) : element.type.new
        end
        self.send("#{name}=", value)
      end
      
    end
    
  end
  
end