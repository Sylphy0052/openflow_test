#
# Forwarding database (FDB)
#
# Author: Yasuhito Takamiya <yasuhito@gmail.com>
#
# Copyright (C) 2008-2012 NEC Corporation
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License, version 2, as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#


class ForwardingEntry
  include Trema::Logger

  attr_reader :mac
  attr_reader :port_no
  attr_reader :dpid
  attr_writer :age_max

  def initialize mac, port_no, age_max, dpid
    @mac = mac
    @port_no = port_no
    @age_max = age_max
    @dpid = dpid
    @last_update = Time.now
    debug "New entry: MAC address = #{ @mac.to_s }, port number = #{ @port_no }"
  end

  
  def update port_no
    debug "Update: The port number of #{ @mac.to_s } has been changed #{ @port_no } => #{ port_no }"
    @port_no = port_no
    @last_update = Time.now
  end


  def aged_out?
    aged_out = Time.now - @last_update > @age_max
    puts "aged out MAC address #{@mac} port #{@port_no}!" if aged_out
    aged_out
  end
end


#############################################################################
# A database that keep pairs of MAC address and port number
#############################################################################
class FDB
  DEFAULT_AGE_MAX = 600

  def initialize
    @db = {}
  end

  def port_no_of mac
    dest = @db[mac]
    if dest
      dest.port_no
    else
      nil
    end
  end

  def learn mac, port_no, dpid = nil
    entry = @db[ mac ]
    if entry
      entry.update port_no
      puts "update #{mac} for port #{port_no} at dpid = #{dpid}"
    else
      new_entry = ForwardingEntry.new( mac, port_no, DEFAULT_AGE_MAX, dpid )
      @db[new_entry.mac] = new_entry
      puts "lean #{mac} for port #{port_no} at dpid = #{dpid}"
    end
  end

  def belong_dpid_of mac
    dest = @db[ mac ]
    if dest
      dest.dpid
    else
      nil
    end
  end
  
  def exist_entry? macaddr
    @db.each do | mac, entry |
      return true if entry.mac == macaddr
    end
    return nil
  end

  
  def age
    @db.delete_if do | mac, entry |
      entry.aged_out?
    end
  end


  def debug_info
    @db.each do | mac, entry |
      p entry
    end
  end
end


### Local variables:
### mode: Ruby
### coding: utf-8
### indent-tabs-mode: nil
### End:
