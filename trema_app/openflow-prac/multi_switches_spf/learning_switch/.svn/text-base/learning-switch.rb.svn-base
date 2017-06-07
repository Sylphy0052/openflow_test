#
# Simple learning switch application in Ruby
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


require "fdb"
require "arp"
require "nat"

#
# A OpenFlow controller class that emulates a layer-2 switch.
#
class LearningSwitch < Trema::Controller
  DEFAULT_AGE_MAX = 5
  #add_timer_event :age_fdb, 5, :periodic
  #add_timer_event :check_fdb, 5, :periodic
  periodic_timer_event :age_fdb, 5
  #periodic_timer_event :debug_fdb, 5

  def start
    @fdb = FDB.new   #instance variable, not class variable.
    @nat = NAT.new
    @arp = Arp.new
  end


  def packet_in datapath_id, message
    # assume that first three octets of ipv4 address is vlan id.
    #vlan = message.ipv4_saddr.to_s.slice( /(\d{1,3}\.){3}/ ) if message.ipv4?  
    #vlan = 1
    
    @fdb.learn message.macsa, message.in_port
    
    if message.arp? and @nat.has_ip? message.arp_tpa and @nat.has_mac_for?( message.arp_tpa )
      @arp.reply_for message, @nat.mac_for( message.arp_tpa )
      return
    end
    
    port_no = @fdb.port_no_of message.macda
    if port_no
      flow_mod datapath_id, message, port_no
      packet_out datapath_id, message, port_no
    else
      flood datapath_id, message
    end
  end


  def age_fdb
    @fdb.age
  end

  def debug_fdb
    @fdb.debug_info
  end

  ##############################################################################
  private
  ##############################################################################


  def flow_mod datapath_id, message, port_no
    actions = Array.new( [ Trema::ActionOutput.new( :port => port_no ) ] )
    
    @nat.nat message, actions if message.ipv4?
      
    send_flow_mod_add(
      datapath_id,
      :match => ExactMatch.from( message ),
      :actions => actions,
      :hard_timeout => DEFAULT_AGE_MAX
    )
  end

  
  def packet_out datapath_id, message, port_no
    actions = Array.new( [ Trema::ActionOutput.new( :port => port_no ) ] )
    
    @nat.nat message, actions if message.ipv4?
      
    send_packet_out(
      datapath_id,
      :packet_in => message,
      :actions => actions
    )
  end


  def flood datapath_id, message
    packet_out datapath_id, message, OFPP_FLOOD
    
    mac = message.macsa.to_s
    if message.ipv4?
      ip = message.ipv4_saddr.to_s
    else
      ip = "0.0.0.0"
    end
    puts "flooding packets from #{mac} (#{ip})!"
  end
end


### Local variables:
### mode: Ruby
### coding: utf-8
### indent-tabs-mode: nil
### End:
