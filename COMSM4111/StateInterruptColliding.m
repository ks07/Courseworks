classdef StateInterruptColliding
    %STATEINTERRUPTCOLLIDING Interrupt state to avoid collisions.
    %   Detailed explanation goes here
    
    properties
        ctr;
    end
    
    properties(Constant)
        TRIGGER_COLL_BOUND = 70; % Min distance to another UAV to trigger
    end
    
    methods
        function state = StateInterruptColliding()
            state.ctr = 0;
        end
        function newState = step(state, ~, c)
            if state.ctr == 0
                % About to go out of range, turn!
                c.uav.cmdTurn(-6);
                c.uav.cmdSpeed(20);
                
                newState = state;
            else
                % Should have turned away, go forward once.
                c.uav.cmdTurn(0);
                c.uav.cmdSpeed(20);
                
                newState = StateLost();
            end

            c.uav.updateState(c.dt);
        end
    end
    methods(Static)
        function interruptState = triggered(state,t,c,gps,ppm)
            msgs = c.uav.comm_rx();
            
            %Assume that all messages are location broadcasts, and ignore
            %this handling near launch time.
            if size(msgs,1) > 0 && t > 30 && ~isa(state,'StateInterruptColliding')
                locs = msgs(:,2:3);
                for i=1:size(locs,1)
                    loc = locs(i,:);
                    % Ignore what we presume to be our own message
                    if any(loc ~= c.prevGPS) && (pdist([gps;loc]) < StateInterruptColliding.TRIGGER_COLL_BOUND)
                        interruptState = StateInterruptColliding();
                        return;
                    end
                end
            end
            interruptState = false;
        end
    end
    
end

