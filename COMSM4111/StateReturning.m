classdef StateReturning < handle
    %STATERETURNING Interrupt state, moving away from the range
    % limit.
    %   Detailed explanation goes here
    
    properties
        endpick;
        trn;
        spd;
        ctr;
    end
    
    methods
        function state = StateReturning(bestend,trn,spd,steps)
            state.endpick = mod(bestend-2,steps)+1;
            state.trn = trn;
            state.spd = spd;
            state.ctr = 1;
        end
        function newState = step(state, ~, c)
            if state.ctr < state.endpick
                % More turns to take.
                c.uav.cmdTurn(state.trn);
                c.uav.cmdSpeed(state.spd);
                
                c.uav.updateState(c.dt);
                
                state.ctr = state.ctr + 1;
                newState = state;
            else
                % Forward once, then resume search.
                c.uav.cmdTurn(0);
                c.uav.cmdSpeed(10);
                
                c.uav.updateState(c.dt);
                
                newState = StateLost();
            end
        end
    end
    
end
