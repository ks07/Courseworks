classdef StateInterruptColliding < handle
    %STATEINTERRUPTCOLLIDING Interrupt state to avoid collisions.
    %   Detailed explanation goes here
    
    properties
        ctr;
        points;
        steps;
        stepAng;
        otherPos;
        otherPPM;
        initDist;
    end
    
    properties(Constant)
        TRIGGER_COLL_BOUND = 100; % Min distance to another UAV to trigger
        STEPS = 5;
    end
    
    methods
        function state = StateInterruptColliding(otherPos, initDist, ppm)
            state.ctr = 1;
            state.otherPos = otherPos;
            state.initDist = initDist;
            state.stepAng = -360 / state.STEPS;
            state.points = zeros(state.STEPS,1);
            state.otherPPM = ppm;
        end
        function newState = step(state, t, c)
            [gps,~] = c.getInput(t);
            if state.otherPPM
                % Try continuing.
                c.uav.cmdTurn(0);
                c.uav.cmdSpeed(20);
                newState = StateHex();
            elseif state.ctr < 4
                % Wait, hopefully let the other move.
                c.uav.cmdTurn(6);
                c.uav.cmdSpeed(20);
                newState = state;
            else
                c.uav.cmdTurn(6);
                c.uav.cmdSpeed(20);
                newState = StateHex();
            end
            
            c.uav.updateState(c.dt);
        end
    end
    methods(Static)
        function interruptState = triggered(state,t,c,gps,ppm)
            msgs = double(c.uav.comm_rx(Network.TYPE_COLLIDE)); %Conv to dbl
            
            %Assume that all messages are location broadcasts, and ignore
            %this handling near launch time.
            if size(msgs,1) > 0 && t > 30 && ~isa(state,'StateInterruptColliding') && ~isa(state,'StateReturning')
                locs = msgs(:,2:3);
                preds = msgs(:,4:5);
                ppms = msgs(:,6);
                for i=1:size(locs,1)
                    loc = locs(i,:);
                    pred = preds(i,:);
                    ppm = ppms(i,:);
                    % Ignore what we presume to be our own message
                    if any(loc ~= single(c.prevGPS)) && (pdist([gps;loc]) < StateInterruptColliding.TRIGGER_COLL_BOUND)
                        interruptState = StateInterruptColliding(pred,pdist([gps;pred]),ppm < c.prevPPM);
                        return;
                    end
                end
            end
            interruptState = false;
        end
    end
    
end

