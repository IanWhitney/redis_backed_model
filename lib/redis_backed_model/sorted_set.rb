module RedisBackedModel

  class SortedSet
  require 'date'
    
    def self.matches?(key)
      key.match(/score_\[(\w+)\|(\w+)\]/) ? true : false
    end
  
    # def initialize(model, model_id, definition)
    #   self.model      = model
    #   self.model_id   = model_id
    #   self.definition = definition
    #   self
    # end
    
    def initialize(object, definition)
      self.model        = object.class
      self.model_id     = object.id
      self.definition   = definition
      self
    end

    # sets a instance variable on object
    #  variable name is to_instance_variable_name
    #  value is self
    def add_to(object)
      object.instance_variable_set(self.to_instance_variable_name, self)
    end

    # Returns a description of the object that does not contain illegal characters
    def to_instance_variable_name
      "sorted_set_for_#{key_for}_by_#{key_by}".instance_variableize
    end
  
    # Serializes the object as a redis command to create a sorted set.
    def to_redis
      "zadd|#{key}|#{score}|#{member}"
    end
  
    private
      
      attr_accessor :model, :model_id, :definition
      
      def definition_keys
        definition.keys.first
      end
      
      def definition_values
        definition.values.first
      end
      
      def key_by
        parse_definition(definition_keys)[1]
      end
      
      def key_for
        parse_definition(definition_keys)[0]        
      end

      def key_model_name
        model.to_s.underscore.pluralize
      end

      def key_for_value
        parse_definition(definition_values)[0]
      end

      def member
        model_id
      end
        
      def key
        "#{key_model_name}_for_#{key_for}_by_#{key_by}:#{key_for_value}"
      end

      def score
        score = parse_definition(definition_values)[1]
        key_by == 'date' ? Date.parse(score).to_time.to_f : score
      end
      
      def parse_definition(string)
        string.match(/.*\[(\S+)\]/)[1].split('|')
      end
  
  end

end