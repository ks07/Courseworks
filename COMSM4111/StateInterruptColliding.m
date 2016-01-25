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
            newState = StateIncreasing();
            [gps,~] = c.getInput(t);
            if pdist([c.prevGPS;state.otherPos]) < pdist([gps;state.otherPos])
                % If we are already moving away from the one ~behind us, go
                % straight on one step.
                c.uav.cmdTurn(0);
                c.uav.cmdSpeed(20);
            else
                % We are moving into the other one, turn 180.
                [spd,trn] = c.calcTurn(180);
                c.uav.cmdTurn(trn);
                c.uav.cmdSpeed(spd);
            end
            
            c.uav.updateState(c.dt);
        end
    end
    methods(Static)
        function interruptState = triggered(state,t,c,gps,ppm)
            msgs = c.uav.comm_rx();
            
            %Assume that all messages are location broadcasts, and ignore
            %this handling near launch time.
            if size(msgs,1) > 0 && t > 30 && ~isa(state,'StateInterruptColliding') && ~isa(state,'StateReturning')
                locs = msgs(:,2:3);
                for i=1:size(locs,1)
                    loc = locs(i,:);
                    % Ignore what we presume to be our own message
                    if any(loc ~= c.prevGPS) && (pdist([gps;loc]) < StateInterruptColliding.TRIGGER_COLL_BOUND)
                        % If we are already moving away from the other,
                        % ignore (i.e. the other is driving into us from
                        % behind)
                        if pdist([c.prevGPS;loc]) >= pdist([gps;loc])
                            interruptState = StateInterruptColliding(loc,pdist([gps;loc]));
                            return;
                        end
                    end
                end
            end
            interruptState = false;
        end
    end
    
end

