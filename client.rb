require 'rubygems'
require 'eventmachine'
require 'socket'

require 'sqlite3'

$num_users = 100

class ClientConnection < 
    #EventMachine::Connection
    EM::Protocols::LineAndTextProtocol
  attr_accessor :database, :device_id, :data_buffer

  def initialize(db, device_id)
    @database = db
    @device_id = device_id
    @data_buffer = ""
  end

  def post_init
    send_data("getmsg #{@device_id} 10\r\n")
  end

  def receive_data data
    @data_buffer = @data_buffer + data
    if (@data_buffer =~ /done\n/)
      p @data_buffer
      @data_buffer = ""
      send_data("getmsg #{@device_id} 10\r\n")
    elsif (@data_buffer =~ /nomsg\n/)
      puts "done\n"
      close_connection()
    else
      # continue to receive data.
    end
  end

  def unbind
    puts "Client terminated"
  end
end

STDOUT.sync = true


#EventMachine::run{  EventMachine::connect "localhost", 5040, ClientConnection, nil, 10 }



EventMachine::run{
  $num_users.times{|i|
    EventMachine::connect "localhost", 5040, ClientConnection, nil, i+1
  }
}
