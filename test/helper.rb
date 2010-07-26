require 'rubygems'
require 'test/unit'
require 'shoulda'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'has_constant'

def setup_mongoid
  begin
    require 'mongoid'
    Mongoid.database = Mongo::Connection.new('localhost', @port).db('i18n_test')
  rescue LoadError => e
    puts "can't use Mongoid adapter because: #{e}"
  end
end

def setup_active_record
  begin
    require 'active_record'
    ActiveRecord::Base.connection
    true
  rescue LoadError => e
    puts "can't use ActiveRecord backend because: #{e.message}"
  rescue ActiveRecord::ConnectionNotEstablished
    connect_active_record
    true
  end
end

def connect_active_record
  connect_adapter
  ActiveRecord::Migration.verbose = false
  ActiveRecord::Schema.define(:version => 1) do
    create_table :users, :force => true do |t|
      t.integer :salutation
    end
  end
end

def connect_adapter
  ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => ":memory:")
end

class Test::Unit::TestCase

  def setup
    Mongoid.database.collections.each do |collection|
      begin
        collection.drop
      rescue
      end
    end if defined?(Mongoid)
    User.delete_all if defined?(ActiveRecord)
  end
end
