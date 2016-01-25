classdef Network < handle
    %NETWORK Communications layer
    %   All comms use single precision floats - can send 8 per message
    
    properties
        sending;
        sent;
    end
    
    % Hold some constants for message 'types' for easy access
    properties(Constant)
        TYPE_COLLIDE = 0;
        TYPE_FOUND = 1;
    end
    
    methods
        function net = Network()
        end
        function tx(self,buff)
            % Send a message to all other UAVs.
            % buff is max 32 bytes, tx time is 1s
            if numel(buff) > 8
                error('Tried to send too large message.');
            end
            packet = zeros(1,8,'single');
            packet(1:numel(buff)) = buff;
            self.sending = [self.sending; packet];
        end
        function msgs = rx(self,filter)
            if nargin == 1
                msgs = self.sent;
            elseif ~isempty(self.sent)
                msgs = self.sent(self.sent(:,1)==filter,:);
            else
                msgs = [];
            end
        end
        function step(self)
            self.sent = self.sending;
            self.sending = [];
        end
    end
    
end

