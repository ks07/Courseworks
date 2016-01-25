classdef StateInterruptColliding
    %STATEINTERRUPTCOLLIDING Interrupt state to avoid collisions.
    %   Detailed explanation goes here
    
    properties
        ctr;
        steps;
        stepAng;
        otherPos;
        initDist;
    end
    
    properties(Constant)
        TRIGGER_COLL_BOUND = 100; % Min distance to another UAV to trigger
        STEPS = 5;
    end
    
    methods
        function state = StateInterruptColliding(otherPos, initDist)
            state.ctr = 0;
            state.otherPos = otherPos;
            state.initDist = initDist;
            state.stepAng = -360 / state.STEPS;
        end
        function newState = step(state, t, c)
            [gps,~] = c.getInput(t);
            if pdist([gps;state.otherPos]) > state.initDist
                % We are now getting further away from the other UAV, hold
                c.uav.cmdTurn(0);
                c.uav.cmdSpeed(20);
                
                newState = StateLost();
            else
                % About to go out of range, turn!
                [spd,turn] = c.calcTurn(state.stepAng);
                c.uav.cmdTurn(turn);
                c.uav.cmdSpeed(spd);
                
                newState = state;
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
                        interruptState = StateInterruptColliding(loc,pdist([gps;loc]));
                        return;
                    end
                end
            end
            interruptState = false;
        end
    end
    
end

