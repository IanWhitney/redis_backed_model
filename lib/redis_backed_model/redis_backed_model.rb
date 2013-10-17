module RedisBackedModel
  class RedisBackedModel

    def self.redis_data_structures
      [
        RedisHash,
        RedisSet,
        SortedSet
      ]
    end

    # Checks to see if the redis store has the resource. Returns true if found, false if not 
    def self.exists?(id)
      id && find(id) != []
    end

    # Finds and returns one or more objects by their id.
    # Pass in a single id or an array of ids.
    #   obj.find(1) => obj
    #   obj.find([1,2,3]) => [obj,obj,obj]
    # returns an empty array if no object matches the id in Redis
    #   obj.find(bad_id) => []
    def self.find(*args)
      found = []
      args.flatten.each do |id|
        attributes = $redis.hgetall(instance_redis_hash_key(id))
        found << self.new(attributes.merge({'id' => id})) if attributes.size > 0
      end
      (found.count == 1) ? found.first : found
    end

    def self.redis_name
      self.name.demodulize.underscore
    end


    attr_reader :id

    # Instantiates the object using the provided attributes.
    #   Object creates a data structure (hash, set, sorted set) for each attribute. 
    #   It then uses these structures to set instance variables.
    def initialize(attributes={})
      self.data = []
      add_attributes(attributes)
    end
    
    def add_attributes(attributes)
      if attributes.class == Hash
        attributes.each do |key, value|
          add_data(Hash[key, value])
        end
      else
        raise ArgumentError
      end
    end
    
    # Serializes the object as redis commands.
    def to_redis
      data.map { |d| d.to_redis }
    end

    def redis_name
      self.class.redis_name
    end
    
    private
    
      attr_accessor :data
    
      def self.instance_redis_hash_key(id)
        "#{redis_name}:#{id}"
      end

      def add_attr_reader(data_structure)
        self.instance_variable_set(data_structure.to_instance_variable_name, data_structure.to_instance_variable_value)
        self.class.class_eval { attr_reader data_structure.to_attr_name }
      end

      def add_data(attribute_pair)
        matching_data_structures(attribute_pair).each do |data_structure|
          attribute_data = data_structure.new(self, attribute_pair)
          data << attribute_data
          add_attr_reader(attribute_data) if attribute_data.attr_able?
        end
      end

      def matching_data_structures(attribute_pair)
        self.class.redis_data_structures.select{ |structure| structure.matches?(attribute_pair) }
      end
        
  end
    
end
