classdef StateInterruptColliding < handle
    %STATEINTERRUPTCOLLIDING Interrupt state to avoid collisions.
    %   Detailed explanation goes here
    
    properties
        ctr;
        points;
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
            state.ctr = 1;
            state.otherPos = otherPos;
            state.initDist = initDist;
            state.stepAng = -360 / state.STEPS;
            state.points = zeros(state.STEPS,1);
        end
        function newState = step(state, t, c)
            newState = state;
            [gps,~] = c.getInput(t);
            [spd,trn] = c.calcTurn(360/state.STEPS);
            if state.ctr <= state.STEPS
                % Note positions and make a move.
                % Try 0'ing any coord thats not outside, so we pick the
                % better route?
                state.points(state.ctr) = pdist([gps;state.otherPos]) - pdist([c.prevGPS;state.otherPos]); % Store the diff in dist to origin
                
                c.uav.cmdTurn(trn);
                c.uav.cmdSpeed(spd);
                
                c.uav.updateState(c.dt);
                
                state.ctr = state.ctr + 1;
            else
                % Decision making time.
                [~,bestend] = max(state.points);

                newState = StateReturning(bestend,trn,spd,state.STEPS);
                newState = newState.step(t,c);
            end
        end
    end
    methods(Static)
        function interruptState = triggered(state,t,c,gps,ppm)
            msgs = c.uav.comm_rx();
            
            %Assume that all messages are location broadcasts, and ignore
            %this handling near launch time.
            if size(msgs,1) > 0 && t > 30 && ~isa(state,'StateInterruptColliding') && ~isa(state,'StateFound') && ~isa(state,'StateReturning')
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

