

class Arp < Trema::ARP
  def reply_for message, src_mac
    puts "Send ARP reply!"
    dpid = message.datapath_id
    out_port = message.in_port
    src_ip = message.arp_tpa.to_s
    tgt_ip = message.arp_spa.to_s
    #src_mac = @nat.mac message.arp_tpa.to_s
    tgt_mac = message.arp_sha.to_s


    self.send_packet_out_arp dpid, out_port, src_ip, tgt_ip, src_mac, tgt_mac
  end
end

### Local variables:
### mode: Ruby
### coding: utf-8
### indent-tabs-mode: nil
### End:
