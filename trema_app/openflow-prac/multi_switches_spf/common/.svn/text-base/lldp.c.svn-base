#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <netdb.h>
#include <string.h>
#include <unistd.h>
#include <ctype.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <sys/param.h>
#include <sys/sysctl.h>
#include <arpa/inet.h>
#include <net/if.h>
#include <net/if_arp.h>
#include <net/route.h>
#include <netinet/in.h>
#include <netinet/if_ether.h>
#include <linux/if_packet.h>
#include <linux/if_ether.h>
#include <netinet/ether.h>

/* for Trema */
#include "ruby.h"
#include "trema.h"
extern VALUE mTrema;

/* ethernet header only, now */
bool make_lldp_and_send_message(
#if __WORDSIZE == 64 /* 64 bit  CPU */
			       const unsigned long datapath_id,
#else /* 32 bit  CPU */
			       const unsigned long long datapath_id,
#endif
			       const unsigned int port, const char *src_mac_address, const char *dst_mac_address){
  
  struct ether_addr src_mac_addr;
  struct ether_addr dst_mac_addr;

  ether_aton_r(src_mac_address, &src_mac_addr);
  ether_aton_r(dst_mac_address, &dst_mac_addr);

  buffer *frame = alloc_buffer_with_length( sizeof( ether_header_t ) + sizeof( datapath_id ));
  ether_header_t *ether = append_back_buffer( frame, sizeof( ether_header_t ) ); 
#if __WORDSIZE == 64 /* 64 bit  CPU */
  unsigned long *dpid = append_back_buffer( frame, sizeof( unsigned long ) ); 
#else /* 32 bit  CPU */
  unsigned long long *dpid = append_back_buffer( frame, sizeof( unsigned long long ) ); 
#endif
 
  memcpy(ether->macsa, src_mac_addr.ether_addr_octet, sizeof(src_mac_addr.ether_addr_octet));
  memcpy(ether->macda, dst_mac_addr.ether_addr_octet, sizeof(dst_mac_addr.ether_addr_octet));  
  ether->type = htons( ETH_ETHTYPE_LLDP ); 
  
  memcpy(dpid, &datapath_id, sizeof(datapath_id));  

  fill_ether_padding( frame );   

  openflow_actions *actions = create_actions(); 
  append_action_output( actions, port, UINT16_MAX ); 
  buffer *pout = create_packet_out( get_transaction_id(), UINT32_MAX, OFPP_NONE, actions, frame ); 
  bool ret = send_openflow_message(datapath_id, pout); 
  
  free_buffer( pout ); 
  free_buffer( frame ); 
  delete_actions( actions ); 
  
  return ret;
}


VALUE send_packet_out_lldp(VALUE self, VALUE rb_datapath_id, VALUE rb_src_macaddr){
#if __WORDSIZE == 64 /* 64 bit  CPU */
  unsigned long datapath_id = NUM2ULONG(rb_datapath_id);
#else /* 32 bit  CPU */
  unsigned long long datapath_id = NUM2ULL(rb_datapath_id);
#endif
  unsigned int port = OFPP_FLOOD;

  char *src_macaddr = STR2CSTR(rb_src_macaddr);
  char *dst_macaddr = "01:80:c2:00:00:0e";

  make_lldp_and_send_message(datapath_id, port, src_macaddr, dst_macaddr);
}


VALUE lldp_src_datapath_id(VALUE self){
  packet_in *cpacket;
  Data_Get_Struct(self, packet_in, cpacket);
  const buffer *buf = cpacket->data;
  const unsigned char *frame = STR2CSTR(rb_str_new( buf->data, ( long ) buf->length));
  const unsigned char *nb_datapath_id = frame + sizeof(ether_header_t);

#if __WORDSIZE == 64 /* 64 bit  CPU */
  unsigned long datapath_id;
  memcpy(&datapath_id, nb_datapath_id, sizeof(unsigned long));  
#else /* 32 bit  CPU */  
  unsigned long long datapath_id;
  memcpy(&datapath_id, nb_datapath_id, sizeof(unsigned long long));  
#endif

  /*
  printf("LLDP payload = %x\n", datapath_id);
  */

#if __WORDSIZE == 64 /* 64 bit  CPU */
  return ULONG2NUM(datapath_id);
#else /* 32 bit  CPU */
  return ULL2NUM(datapath_id);
#endif
  
}



Init_LLDP(){
  VALUE class;
  VALUE cPacketIn;

  /*
    add class to send LLDP frame
    example: see ./topology.rb
  */
  class = rb_define_class_under(mTrema, "LLDP", rb_cObject);
  rb_define_method(class, "send_packet_out_lldp", send_packet_out_lldp, 2);



  /*
    add instance method to class PacketIN
    example: message.lldp_src_datapath_id  # => num (datapath_id)
  */
  cPacketIn = rb_define_class_under(mTrema, "PacketIn", rb_cObject );
  rb_define_method(cPacketIn, "lldp_src_datapath_id", lldp_src_datapath_id, 0);
}
