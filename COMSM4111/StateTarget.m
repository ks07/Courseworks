classdef StateTarget < handle
    %STATETARGET Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        target;
    end
    
    methods
        function state = StateTarget(target)
            state.target = target;
        end
        function newState = step(state, t, c)
            newState = state;
            [gps, ~] = c.getInput(t);
            
            prevDist = c.dist(c.prevGPS, state.target);
            newDist = c.dist(gps, state.target);
            
            c.uav.cmdSpeed(10);
            if newDist < prevDist
                c.uav.cmdTurn(0);
            else
                turn = max(2, 6/max(1,newDist/100))
                c.uav.cmdTurn(turn);
            end
            
            c.uav.updateState(c.dt);
        end
    end
    
end
