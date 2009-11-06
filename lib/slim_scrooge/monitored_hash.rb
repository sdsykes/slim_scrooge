# Author: Stephen Sykes

module SlimScrooge
  class MonitoredHash < Hash
    attr_accessor :callsite, :result_set, :monitored_columns
    
    def self.[](monitored_columns, unmonitored_columns, callsite)
      hash = MonitoredHash.new {|hash, key| hash.new_column_access(key)}
      hash.monitored_columns = monitored_columns
      hash.merge!(unmonitored_columns)
      hash.callsite = callsite
      hash
    end
    
    def new_column_access(name)
      if @callsite.columns_hash.has_key?(name)
        @result_set.reload! if @result_set && name != @callsite.primary_key
        Callsites.add_seen_column(@callsite, name)
      end
      @monitored_columns[name]
    end
    
    def []=(name, value)
      if has_key?(name)
        return super
      elsif @result_set && @callsite.columns_hash.has_key?(name)
        @result_set.reload!
        Callsites.add_seen_column(@callsite, name)
      end
      @monitored_columns[name] = value
    end
    
    def keys
      @result_set ? @callsite.columns_hash.keys : super | @monitored_columns.keys
    end
    
    def has_key?(name)
      @result_set ? @callsite.columns_hash.has_key?(name) : super || @monitored_columns.has_key?(name)
    end
    
    alias_method :include?, :has_key?
    
    def to_hash
      @result_set.reload! if @result_set
      @monitored_columns.merge(self)
    end
    
    # Marshal
    # Dump a real hash - can't dump a monitored hash due to default proc
    #
    def _dump(depth)
      Marshal.dump(to_hash)
    end
    
    def self._load(str)
      Marshal.load(str)
    end
  end
end

class Hash
  alias_method :c_update, :update
  def update(other_hash, &block)
    c_update(other_hash.to_hash, &block)
  end
end
