module RamlParser
  class YamlTree
    attr_reader :root

    def initialize(root)
      @root = YamlNode.new(nil, 'root', root)
    end
  end

  class YamlNode
    attr_reader :parent, :key, :value

    def initialize(parent, key, value)
      @parent = parent
      @key = key
      @value = value
    end

    def root
      if @parent != nil
        @parent.root
      else
        self
      end
    end

    def path
      if @parent != nil
        "#{@parent.path}.#{@key}"
      else
        @key
      end
    end

    def each(&code)
      (@value || {}).each { |k,v|
        next_node = YamlNode.new(self, k, v)
        code.call(next_node)
      }
    end

    def map(&code)
      (@value || {}).map { |k,v|
        next_node = YamlNode.new(self, k, v)
        code.call(next_node)
      }
    end
  end

  class YamlHelper
    require 'yaml'

    def self.read_yaml(path)
      # add support for !include tags
      Psych.add_domain_type 'include', 'include' do |_, value|
        case value
          when /^https?:\/\//
            # TODO implement remote loading of included files
            ''
          else
            case value
              when /\.raml$/
                read_yaml(value)
              when /\.ya?ml$/
                read_yaml(value)
              else
                File.read(value)
            end
        end
      end

      # change working directory so that !include works properly
      pwd_old = Dir.pwd
      Dir.chdir(File.dirname(path))
      raw = File.read(File.basename(path))
      node = YAML.load(raw)
      Dir.chdir(pwd_old)
      node
    end

    def self.dump_yaml(yaml)
      YAML.dump(yaml)
    end
  end
end
