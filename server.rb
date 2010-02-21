require 'rubygems'
require 'eventmachine'
require 'socket'

require 'sqlite3'

def create_db(db)
  db.execute( "create table sample_table (id INTEGER PRIMARY KEY, device_id INTEGER, msg TEXT);" )
end


def add_records(db, num_devices, num_records_per_device)
  num_devices.times{|i|
    num_records_per_device.times{|j|
      db.execute( "insert into sample_table (device_id, msg) values (#{i}, 'Sample Text1')")
    }
  }
end

def print_db(db)
  rows = db.execute( "select * from sample_table" )
  p rows
end



#db = SQLite3::Database.new( "new.database" )
#create_db(db) 
#add_records(db, 10,10)
#print_db(db)

 
class DeviceConnection <  EM::Protocols::LineAndTextProtocol
#EventMachine::Connection
  attr_accessor :data_buf

  def post_init
    puts "#{@num}: New connection from Device"
    @data_buf = ""
    #port, ip = Socket.unpack_sockaddr_in(get_peername)
    #print "peername = #{ip}:#{port}  #{get_sockname}\n"

  end

  def receive_data data
    if data == "\r\n"
      p @data_buf
      @data_buf = ""
    else
      @data_buf = @data_buf + data
    end  
  end

  def unbind
    puts "#{@num}: Device Connection Closed"
  end
end


STDOUT.sync = true

EventMachine::run {
  host,port = "localhost", 5040
  EventMachine::start_server host, port, DeviceConnection
  puts "Now accepting connections on address #{host}, port #{port}..."
}
