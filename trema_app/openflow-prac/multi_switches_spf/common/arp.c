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

bool make_arp_and_send_message(
#if __WORDSIZE == 64 /* 64 bit  CPU */
			       const unsigned long datapath_id,
#else /* 32 bit  CPU */
			       const unsigned long long datapath_id,
#endif
			       const unsigned int port, const char *src_mac, const char *dst_mac, const char *sipaddr, const char *tipaddr, const char *smacaddr, const char *tmacaddr){
  /* 
   src_mac -> ether frame source mac address
   dst_mac -> ether frame destination mac address
   sipaddr -> arp source ip address
   tipaddr -> arp target ip address
   smacaddr -> arp source mac address
   tmacaddr -> arp target mac address
  */

  
  struct ether_addr src;
  struct ether_addr dst;
  struct ether_addr arp_src;
  struct ether_addr arp_tgt;
  
  ether_aton_r(src_mac, &src);
  ether_aton_r(dst_mac, &dst);
  ether_aton_r(smacaddr, &arp_src);
  ether_aton_r(tmacaddr, &arp_tgt);

  buffer *frame = alloc_buffer_with_length( sizeof( ether_header_t ) + sizeof( arp_header_t ) ); 
  ether_header_t *ether = append_back_buffer( frame, sizeof( ether_header_t ) ); 
  arp_header_t *arp = append_back_buffer( frame, sizeof( arp_header_t ) ); 

  memcpy(ether->macsa, src.ether_addr_octet, sizeof(src.ether_addr_octet));
  memcpy(ether->macda, dst.ether_addr_octet, sizeof(dst.ether_addr_octet));  
  ether->type = htons( ETH_ETHTYPE_ARP ); 
  
  arp->ar_hrd = htons( ARPHRD_ETHER ); 
  arp->ar_pro = htons( ETH_ETHTYPE_IPV4 ); 
  arp->ar_hln = ETH_ADDRLEN; 
  arp->ar_pln = IPV4_ADDRLEN;
  if(strcmp(dst_mac, "ff:ff:ff:ff:ff:ff") == 0)
    arp->ar_op = htons( ARPOP_REQUEST );
  else
    arp->ar_op = htons( ARPOP_REPLY );
  
  memcpy(arp->sha, arp_src.ether_addr_octet, sizeof(arp_src.ether_addr_octet));
  arp->sip = inet_addr(sipaddr);
  memcpy(arp->tha, arp_tgt.ether_addr_octet, sizeof(arp_tgt.ether_addr_octet));  
  arp->tip = inet_addr(tipaddr);
  
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



VALUE send_packet_out_arp_reply(VALUE self, VALUE rb_datapath_id, VALUE rb_port, VALUE rb_sipaddr, VALUE rb_tipaddr, VALUE rb_smacaddr, VALUE rb_tmacaddr){
#if __WORDSIZE == 64 /* 64 bit  CPU */
  unsigned long datapath_id = NUM2ULONG(rb_datapath_id);
  printf("I am moving on 64 bit CPU!\n");
#else /* 32 bit  CPU */
  unsigned long long datapath_id = NUM2ULL(rb_datapath_id);
  printf("I am moving on 32 bit CPU!\n");
#endif
  unsigned int port = NUM2UINT(rb_port);
  char *sipaddr = STR2CSTR(rb_sipaddr);
  char *tipaddr = STR2CSTR(rb_tipaddr);
  char *smacaddr = STR2CSTR(rb_smacaddr);
  char *tmacaddr = STR2CSTR(rb_tmacaddr);

  /* 
   sipaddr -> arp source ip address
   tipaddr -> arp target ip address
   smacaddr -> arp source mac address
   tmacaddr -> arp target mac address
  */
  make_arp_and_send_message(datapath_id, port, smacaddr, tmacaddr, sipaddr, tipaddr, smacaddr, tmacaddr);  
}


VALUE send_packet_out_arp_request(VALUE self, VALUE rb_datapath_id, VALUE rb_port, VALUE rb_sipaddr, VALUE rb_tipaddr, VALUE rb_smacaddr){
#if __WORDSIZE == 64 /* 64 bit  CPU */
  unsigned long datapath_id = NUM2ULONG(rb_datapath_id);
  printf("I am moving on 64 bit CPU!\n");
#else /* 32 bit  CPU */
  unsigned long long datapath_id = NUM2ULL(rb_datapath_id);
  printf("I am moving on 32 bit CPU!\n");
#endif
  unsigned int port = NUM2UINT(rb_port);

  char *dst_mac = "ff:ff:ff:ff:ff:ff";
  char *sipaddr = STR2CSTR(rb_sipaddr);
  char *tipaddr = STR2CSTR(rb_tipaddr);
  char *smacaddr = STR2CSTR(rb_smacaddr);
  char *tmacaddr = "00:00:00:00:00:00";

  /* 
   src_mac -> ether frame source mac address
   dst_mac -> ether frame destination mac address
   sipaddr -> arp source ip address
   tipaddr -> arp target ip address
   smacaddr -> arp source mac address
   tmacaddr -> arp target mac address
  */
  make_arp_and_send_message(datapath_id, port, smacaddr, dst_mac, sipaddr, tipaddr, smacaddr, tmacaddr);  
}


Init_ARP(){
  VALUE class;

  class = rb_define_class_under(mTrema, "ARP", rb_cObject);
  rb_define_method(class, "send_packet_out_arp_reply", send_packet_out_arp_reply, 6);
  rb_define_method(class, "send_packet_out_arp_request", send_packet_out_arp_request, 5);
}
