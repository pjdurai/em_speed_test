require 'rubygems'
require 'eventmachine'
require 'socket'

require 'sqlite3'


def create_db(db)
  db.execute( "create table tbl_messages (id INTEGER PRIMARY KEY, device_id INTEGER, msg TEXT);" )
end


def add_records(db, num_devices, num_records_per_device)
  num_devices.times{|i|
    num_records_per_device.times{|j|
      db.execute( "insert into tbl_messages (device_id, msg) values (#{i}, 'Sample Text1')")
    }
  }
end

def print_db(db)
  rows = db.execute( "select * from tbl_messages" )
  p rows
end


class DeviceConnection <  EM::Protocols::LineAndTextProtocol #EventMachine::Connectionn
  attr_accessor  :database

  def initialize(database)
    @database = database
  end

  def post_init
    puts "#{@num}: New connection from Device"
    #port, ip = Socket.unpack_sockaddr_in(get_peername)
    #print "peername = #{ip}:#{port}  #{get_sockname}\n"
  end

  def receive_data (line)
    p line
    if (line =~ /getmsg (\d+) (\d+)/)
      @device_id = $1
      num_messages = $2
      print "get message #{@device_id}   #{num_messages}\n"
      records = get_records(@device_id, num_messages)
      if records.size == 0 then
        send_data("nomsg\n")
      else
        records.each{|record|
          record_str = "#{record[0]}   #{record[1]}  #{record[2]}\n"
          send_data(record_str)
          @database.execute( "delete from tbl_messages where id = #{record[0]}" )
        }
        send_data("done\n")
      end
    end
  end

  def get_records(device_id, num_messages)
    rows = @database.execute( "select * from tbl_messages where device_id = #{device_id} limit #{num_messages}" )
    return rows
  end

  def process_line(line)
  end

  def unbind
    puts "#{@num}: Device Connection Closed"
  end
end


db = SQLite3::Database.new( "new.database" )
#create_db(db) 
#add_records(db, 100,500)
#print_db(db)
#exit(0)


STDOUT.sync = true

EventMachine::run {
  host,port = "localhost", 5040
  EventMachine::start_server host, port, DeviceConnection, db
  puts "Now accepting connections on address #{host}, port #{port}..."
}
