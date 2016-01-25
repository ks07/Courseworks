classdef StateTarget < handle
    %STATETARGET State to fly towards a target, in a spiral motion.
    %   Detailed explanation goes here
    
    properties
        target;
    end
    
    properties(Constant)
        DIST_CUTOFF = 150;
        PPM_CUTOFF = 0.9;
    end
    
    methods
        function state = StateTarget(target)
            state.target = target;
        end
        function newState = step(state, t, c)
            newState = state;
            [gps, ppm] = c.getInput(t);
            
            prevDist = c.dist(c.prevGPS, state.target);
            newDist = c.dist(gps, state.target);
            
            c.uav.cmdSpeed(10);
            if newDist < state.DIST_CUTOFF || ppm > state.PPM_CUTOFF
                newState = StateIncreasing();
                newState = newState.step(t,c);
                return;
            elseif newDist < prevDist
                c.uav.cmdTurn(0);
            else
                turn = max(2, 6/max(1,newDist/100));
                c.uav.cmdTurn(turn);
            end
            
            c.uav.updateState(c.dt);
        end
    end
    
end
