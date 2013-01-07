## -----------------------------------------------------------------------
## This file contains the Junos specific RPC methods that are generated 
## specifically and different as generated by the Netconf::RPC::Builder 
## module.  These are specifically the following:
##
##   get_configuration      - alternative NETCONF: 'get-config'
##   load_configuration     - alternative NETCONF: 'edit-config'
##   lock_configuration     - alternative NETCONF: 'lock'
##   commit_configuration   - alternative NETCONF: 'commit'
##
## note: unlock_configuration is not included in this file since
##       the Netconf::RPC::Builder works "as-is" in this case
## -----------------------------------------------------------------------

module Netconf
  module RPC
    module JUNOS            
      
      def lock_configuration
        lock( 'candidate' )
      end      
      
      def check_configuration
        validate( 'candidate' )
      end            
      
      def commit_configuration( params = nil, attrs = nil )
        rpc = Netconf::RPC::Builder.commit_configuration( params, attrs )
        Netconf::RPC.set_exception( rpc, Netconf::CommitError )
        @trans.rpc_exec( rpc )   
      end

      def get_configuration( *args )
              
        filter = nil
        
        while arg = args.shift
          case arg.class.to_s
          when /^Nokogiri/ 
            filter = case arg
              when Nokogiri::XML::Builder  then arg.doc.root
              when Nokogiri::XML::Document then arg.root
              else arg
              end            
          when 'Hash' then attrs = arg
          end
        end

        rpc = Nokogiri::XML('<rpc><get-configuration/></rpc>').root
        Netconf::RPC.add_attributes( rpc.first_element_child, attrs ) if attrs            
        
        if block_given?
          Nokogiri::XML::Builder.with(rpc.at( 'get-configuration' )){ |xml|
            xml.configuration {
              yield( xml )
          }}
        elsif filter
          f_node = Nokogiri::XML::Node.new( 'configuration', rpc )
          f_node << filter.dup                    # *MUST* use the .dup so we don't disrupt the original filter
          rpc.first_element_child << f_node
        end
               
        @trans.rpc_exec( rpc )
      end
      
      def load_configuration( *args )
                
        config = nil
        
        # default format is XML
        attrs = { :format => 'xml' }
        
        while arg = args.shift
          case arg.class.to_s
          when /^Nokogiri/ 
            config = case arg
              when Nokogiri::XML::Builder  then arg.doc.root
              when Nokogiri::XML::Document then arg.root
              else arg
              end                
          when 'Hash' then attrs = arg
          when 'Array' then config = arg.join("\n")
          when 'String' then config = arg
          end
        end
        
        case attrs[:format]
        when 'set'
          toplevel = 'configuration-set'
          attrs[:format] = 'text'
          attrs[:action] = 'set'          
        when 'text'
          toplevel = 'configuration-text'          
        when 'xml'
          toplevel = 'configuration'          
        end
                        
        rpc = Nokogiri::XML('<rpc><load-configuration/></rpc>').root
        ld_cfg = rpc.first_element_child
        Netconf::RPC.add_attributes( ld_cfg, attrs ) if attrs   
        
        if block_given?
          if attrs[:format] == 'xml'
            Nokogiri::XML::Builder.with( ld_cfg ){ |xml|
              xml.send( toplevel ) {
                yield( xml )
            }} 
          else
            config = yield  # returns String | Array(of stringable)            
            config = config.join("\n") if config.class == Array  
          end
        end
        
        if config
          c_node = Nokogiri::XML::Node.new( toplevel, rpc )
          if attrs[:format] == 'xml'
            c_node << config.dup        # duplicate the config so as to not distrupt it            
          else
            # config is stringy, so just add it as the text node
            c_node.content = config
          end
          ld_cfg << c_node
        end
                                           
        # set a specific exception class on this RPC so it can be
        # properlly handled by the calling enviornment
        
        Netconf::RPC::set_exception( rpc, Netconf::EditError )    
        @trans.rpc_exec( rpc )
      end      
            
    end # module: JUNOS    
  end # module: RPC
end # module: Netconf
