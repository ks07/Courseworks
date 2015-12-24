classdef Network < handle
    %NETWORK Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        sending;
        sent;
    end
    
    methods
        function net = Network()
            
        end
        function sent = tx(self,buff)
            % Send a message to all other UAVs.
            % buff is max 32 bytes, tx time is 1s
            % TODO: Actually send to others
            self.sending = [self.sending; buff];
            sent = true;
        end
        function msgs = rx(self)
            msgs = self.sent;
        end
        function step(self)
            self.sent = self.sending;
            self.sending = [];
        end
    end
    
end

