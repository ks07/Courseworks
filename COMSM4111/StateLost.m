classdef StateLost < handle
    %STATELOST Initial state, when we have no information from sensors
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function state = StateLost()
        end
        function newState = step(state, t, c)
            newState = state;
            [~, ppm] = c.getInput(t);
            
            if ppm > c.prevPPM
                newState = StateIncreasing();
                newState = newState.step(t,c);
            else
                c.uav.cmdTurn(0.1);
                c.uav.cmdSpeed(20);
            
                c.uav.updateState(c.dt);
            end
        end
    end
    
end

