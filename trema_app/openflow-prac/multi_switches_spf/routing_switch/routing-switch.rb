# -*- coding: utf-8 -*-
#
# Monitor switch on/off
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




require "../common/topology"
require "../common/fdb"


class SwitchMonitor < Controller
  DEFAULT_AGE_MAX = 120
  periodic_timer_event :show_topology, 10
  periodic_timer_event :age_fdb, 5
  periodic_timer_event :topology_probe, 5

  
  def start
    @topology = Topology.new
    @lldp = LLDP.new
    @fdb = FDB.new
  end

  # handler for switch boots
  def switch_ready datapath_id
    @topology.add_sw datapath_id
  end

  # handler for switch die
  def switch_disconnected datapath_id
    @topology.del_sw datapath_id
  end
  
  def packet_in datapath_id, message
    if message.lldp?
      @topology.update_topology message
      # return because, a switch is wrong detect link to any other switch 
      # affects of via adjoing switch
      return
    end

    # this logic is need to thing again
    if not @fdb.exist_entry? message.macsa or (@fdb.belong_dpid_of message.macsa) == datapath_id
      @fdb.learn message.macsa, message.in_port, datapath_id
    end
    
    if @fdb.exist_entry? message.macda
      dst_dpid = @fdb.belong_dpid_of message.macda
      path = @topology.path datapath_id, dst_dpid
      
      puts "shortest path from datapath_id = #{datapath_id} is"
      p path
      
      path.each do | dpid |
        if dpid != dst_dpid
          port_no = @topology.port_no_of dpid, path[(path.index dpid) + 1]
          flow_mod dpid, message, port_no
          puts "send flow mod to dpid = #{dpid} port_no= #{port_no}, dst_dpid = #{dst_dpid}"
        else 
          port_no = @fdb.port_no_of message.macda
          flow_mod dpid, message, port_no
          puts "send flow mod to dpid = #{dpid} port_no= #{port_no}, dst_dpid = #{dst_dpid}"
        end
      end


      # consist for not first switch may send packet_in message to the controller
      if datapath_id == dst_dpid
        port_no = @fdb.port_no_of message.macda
        packet_out datapath_id, message, port_no
        puts "packets_out  dpid = #{datapath_id}, port = #{port_no}"
      else
        port_no = @topology.port_no_of path[0], path[1]
        packet_out datapath_id, message, port_no
        puts "packets_out  dpid = #{datapath_id}, port = #{port_no}"
      end
    else
      hosts = @topology.hosts
      
      puts "mac = #{message.macda} is not in FDB"
      puts "ports to any host in this topology is"
      p hosts

      hosts.each do | dpid, all_ports |
        puts "broadcast via controller from dpid = #{datapath_id} to #{dpid}"
        packet_out_port_array dpid, message, all_ports
      end
    end
  end

  def features_reply datapath_id, message
    @topology.update_hosts datapath_id, (message.ports.collect { | each | each.number })
  end

  def age_fdb
    @fdb.age
  end

  def debug_fdb
    @fdb.debug_info
  end
  


  ###########################################################################
  private
  ###########################################################################
  def flow_mod datapath_id, message, port_no
    actions = Array.new( [ Trema::ActionOutput.new( :port => port_no ) ] )
    matches = Match.from(message, :inport, :dl_src, :vlan_tci, :dl_type, :nw_tos, :nw_proto)
    
    send_flow_mod_add(datapath_id, :match => matches, :actions => actions,
                      :hard_timeout => DEFAULT_AGE_MAX, :idle_timeout => DEFAULT_AGE_MAX)
  end

  
  def packet_out datapath_id, message, port_no
    actions = Array.new( [ Trema::ActionOutput.new( :port => port_no ) ] )
    send_packet_out(datapath_id, :packet_in => message, :actions => actions)
  end

  def packet_out_port_array datapath_id, message, all_ports
    actions = []
    
    all_ports.each do | port |
      actions << Trema::ActionOutput.new(:port => port)
    end
      
    send_packet_out(datapath_id, :packet_in => message, :actions => actions)
  end

  def show_topology
    @topology.show
  end

  def topology_probe
    @topology.switches.each do | dpid |
      @lldp.probe dpid
      # request for all ports that are link up
      send_message dpid, FeaturesRequest.new
    end
  end

end


### Local variables:
### mode: Ruby
### coding: utf-8
### indent-tabs-mode: nil
### End:
