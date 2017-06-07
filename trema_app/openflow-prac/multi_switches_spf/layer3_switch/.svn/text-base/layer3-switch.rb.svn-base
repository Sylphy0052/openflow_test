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


$DEFAULT_GW_MAC = "02:00:00:00:00:ff"
require "../common/fdb"
require "../common/arp"
require "interface"
require "fdb-L3-extend"


#
# A OpenFlow controller class that emulates a layer-2 switch.
#
class LearningSwitch < Trema::Controller
  DEFAULT_AGE_MAX = 5
  #add_timer_event :age_fdb, 5, :periodic
  periodic_timer_event :age_fdb, 5
  #periodic_timer_event :debug_fdb, 5

  def start
    @fdb = FDB.new
    @interface = { IP.new("192.168.100.1") => L3_INTERFACE.new("192.168.100.1", 24) ,
                   IP.new("192.168.200.1") => L3_INTERFACE.new("192.168.200.1", 24)
    } 
    @arp = ARP.new
    #p (ForwardingEntry.new "00:00:00:00:00:00", "192.168.1.1", 1, 120, nil).port_no
    @dst_gw = Match.new(:dl_dst => $DEFAULT_GW_MAC)
  end


  def packet_in datapath_id, message    
    if message.arp_request? and @interface.has_key? message.arp_tpa
      @fdb.learn message.macsa, message.arp_spa, message.in_port, datapath_id
      @arp.reply_for message, (@interface[message.arp_tpa]).macaddr
      return
    elsif message.arp_reply?
      @fdb.learn message.macsa, message.arp_spa, message.in_port, datapath_id    
      return
    elsif message.ipv4?
      @fdb.learn message.macsa, message.ipv4_saddr, message.in_port, datapath_id    
    end

    port_no = @fdb.port_no_of message.ipv4_daddr
    
    if port_no
      flow_mod datapath_id, message, port_no
      packet_out datapath_id, message, port_no
    elsif message.ipv4?
      @interface.each do | key, interface |
        if interface.reach? message.ipv4_daddr
          sender_mac = interface.macaddr
          sender_ip = interface.ipaddr
          @arp.request_for message, sender_mac, sender_ip
          return
        end
      end
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
    actions = []
    
    
    if @dst_gw.compare ExactMatch.from(message)
      # address swapping like a router
      actions << ActionSetDlSrc.new(:dl_src => Mac.new($DEFAULT_GW_MAC))
      actions << ActionSetDlDst.new(:dl_dst => @fdb.mac_of(message.ipv4_daddr))
    end
    actions << Trema::ActionOutput.new(:port => port_no)

    matches = ExactMatch.from(message)
    
    send_flow_mod_add(datapath_id, :match => matches, :actions => actions, :idle_timeout => DEFAULT_AGE_MAX)
  end


  def packet_out datapath_id, message, port_no
    actions = []

    if @dst_gw.compare ExactMatch.from(message)
      # address swapping like a router
      actions << ActionSetDlSrc.new(:dl_src => Mac.new($DEFAULT_GW_MAC))
      actions << ActionSetDlDst.new(:dl_dst => @fdb.mac_of(message.ipv4_daddr))
    end
    actions << Trema::ActionOutput.new(:port => port_no)

    send_packet_out(datapath_id, :packet_in => message, :actions => actions)
  end

end


#
# Extend IP class to use hash key
#
class Trema::IP
  extend Forwardable
  def_delegator :Array, :hash

  # @return [Boolean] if other matches or not the attribute type value.
  def == other
    @value == other.value
  end
  
  # @return [Boolean] if other matches or not the attribute type value.
  def eql? other
    @value == other.value
  end
end



### Local variables:
### mode: Ruby
### coding: utf-8
### indent-tabs-mode: nil
### End:
