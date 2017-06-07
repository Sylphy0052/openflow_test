 class FDB
   def initialize
     @db = {}
   end
 
   def lookup mac
     @db[ mac ]
   end
 
   def learn mac, port_number
     @db[ mac ] = port_number
   end
 end