# Author: Stephen Sykes

module SlimScrooge
  class MonitoredHash < Hash
    attr_accessor :callsite, :result_set
    
    def self.[](original_hash, callsite, result_set)
      hash = super(original_hash)
      hash.callsite = callsite
      hash.result_set = result_set
      hash
    end
    
    def [](name)
      if @callsite.columns_hash.has_key?(name)
        @result_set.reload! if @result_set && name != @callsite.primary_key
        Callsites.add_seen_column(@callsite, name)
      end
      super
    end
    
    def []=(name, value)
      if @result_set && @callsite.columns_hash.has_key?(name)
        @result_set.reload!
      end
      super
    end
    
    def keys
      @result_set ? @callsite.columns_hash.keys : super
    end
    
    def has_key?(name)
      @result_set ? @callsite.columns_hash.has_key?(name) : super
    end
    
    alias_method :include?, :has_key?
  end
end
