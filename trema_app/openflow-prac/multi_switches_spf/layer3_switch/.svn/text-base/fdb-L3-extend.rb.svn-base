
# ../common/fdb.rb is only for Layer 2, so exted classes: FDB and ForwardingEntry, for Layer 3
# override class methods only need to exted for layer 3

class ForwardingEntry
  include Trema::Logger

  attr_reader :mac, :ip, :port_no, :dpid
  attr_writer :age_max

  def initialize mac, ip, port_no, age_max, dpid
    @mac = mac
    @ip = ip
    @port_no = port_no
    @age_max = age_max
    @dpid = dpid
    @last_update = Time.now
    debug "New entry: MAC address = #{ @mac.to_s }, port number = #{ @port_no }"
  end

  def update port_no, mac
    debug "Update: The port number of #{ @mac.to_s } has been changed #{ @port_no } => #{ port_no}"
    @port_no = port_no
    @mac = mac
    @last_update = Time.now
  end

  
end

class FDB

  # describe args
  # mac -> Trema::Mac
  # ip -> Trema::IP
  # port_no -> Integer
  # dpid -> Integer
  def learn mac, ip, port_no, dpid = nil
    entry = @db[ip]
    if entry
      entry.update port_no, mac
      puts "update #{mac} for port #{port_no} at dpid = #{dpid}"
    else
      new_entry = ForwardingEntry.new( mac, ip, port_no, DEFAULT_AGE_MAX, dpid )
      @db[new_entry.ip] = new_entry
      puts "lean #{mac} for port #{port_no} at dpid = #{dpid}"
    end
  end

  def mac_of ip
    dest = @db[ip]
    if dest
      dest.mac
    else
      nil
    end
  end
end


# -*- coding: euc-jp -*-
### Local variables:
### mode: Ruby
### coding: utf-8
### indent-tabs-mode: nil
### End:

