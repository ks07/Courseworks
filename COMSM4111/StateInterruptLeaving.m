classdef StateInterruptLeaving
    %STATEINTERRUPTLEAVING Interrupt state, we are dangerously close to the
    % range limit.
    %   Detailed explanation goes here
    
    properties
    end
    
    properties(Constant)
        TRIGGER_POS_BOUND = 800; % Min distance in any direction to trigger
    end
    
    methods
        function state = StateInterruptLeaving()
        end
        function newState = step(~, ~, c)
            % About to go out of range, turn!
            c.uav.cmdTurn(-1);
            c.uav.cmdSpeed(20);

            c.uav.updateState(c.dt);

            newState = StateReturning(); % Don't need to step this, wait one
        end
    end
    methods(Static)
        function interruptState = triggered(state,t,c,gps,ppm)
            if ~isa(state,'StateReturning') && max(abs(gps)) > StateInterruptLeaving.TRIGGER_POS_BOUND
                interruptState = StateInterruptLeaving();
            else
                % Not triggered
                interruptState = false;
            end
        end
    end
    
end

