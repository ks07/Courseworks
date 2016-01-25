classdef StateInterruptLeaving < handle
    %STATEINTERRUPTLEAVING Interrupt state, we are dangerously close to the
    % range limit.
    %   Detailed explanation goes here
    
    properties
        ctr;
        points;
    end
    
    properties(Constant)
        TRIGGER_POS_BOUND = 800; % Min distance in any direction to trigger
        STEPS = 5;
    end
    
    methods
        function state = StateInterruptLeaving()
            state.ctr = 1;
            state.points = zeros(state.STEPS,1);
        end
        function newState = step(state, t, c)
            % About to go out of range, turn!
            newState = state;
            [gps,~] = c.getInput(t);
            [spd,trn] = c.calcTurn(360/state.STEPS);
            if state.ctr <= state.STEPS
                % Note positions and make a move.
                state.points(state.ctr) = pdist([gps;0 0]) - pdist([c.prevGPS;0 0]); % Store the diff in dist to origin
                
                c.uav.cmdTurn(trn);
                c.uav.cmdSpeed(spd);
                
                c.uav.updateState(c.dt);
                
                state.ctr = state.ctr + 1;
            else
                % Decision making time.
                [~,bestend] = min(state.points);

                newState = StateReturning(bestend,trn,spd,state.STEPS);
                newState = newState.step(t,c);
            end
        end
    end
    methods(Static)
        function interruptState = triggered(state,t,c,gps,ppm)
            if ~isa(state,'StateReturning') && ~isa(state,'StateInterruptLeaving') && max(abs(gps)) > StateInterruptLeaving.TRIGGER_POS_BOUND
                interruptState = StateInterruptLeaving();
            else
                % Not triggered
                interruptState = false;
            end
        end
    end
    
end

