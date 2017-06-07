

class Trema::ARP
  # message -> Trema message object (ARP request)
  # src_mac -> Trema::Mac
  # return -> none
  def reply_for message, src_mac
    puts "Send ARP reply!"
    dpid = message.datapath_id
    out_port = message.in_port
    src_ip = message.arp_tpa.to_s
    tgt_ip = message.arp_spa.to_s
    tgt_mac = message.arp_sha.to_s

    self.send_packet_out_arp_reply dpid, out_port, src_ip, tgt_ip, src_mac.to_s, tgt_mac
  end


  # message -> Trema message object (message need to forward)
  # src_mac -> Trema::Mac
  # return -> none
  def request_for message, src_mac, src_ip
    puts "Send ARP request!"
    dpid = message.datapath_id
    out_port = Trema::Controller::OFPP_FLOOD
    tgt_ip = message.ipv4_daddr.to_s
    
    self.send_packet_out_arp_request dpid, out_port, src_ip.to_s, tgt_ip, src_mac.to_s
  end
end

### Local variables:
### mode: Ruby
### coding: utf-8
### indent-tabs-mode: nil
### End:
