classdef Network < handle
    %NETWORK Communications layer
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
            if numel(buff) > 4
                error('Tried to send too large message.');
            end
            packet = zeros(1,5);
            packet(2:1+numel(buff)) = buff;
            packet(1) = numel(buff);
            self.sending = [self.sending; packet];
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

