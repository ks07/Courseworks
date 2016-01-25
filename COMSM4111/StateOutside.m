classdef StateOutside < handle
    %STATEOUTSIDE Cloud has left us behind.
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function state = StateOutside()
        end
        function newState = step(state, t, c)
            [~, ppm] = c.getInput(t);
            
            if ppm > c.prevPPM
                % Are moving inside, keep going straight for a step.
                c.uav.cmdTurn(0);
                c.uav.cmdSpeed(10);
                
                c.uav.updateState(c.dt);
                
                newState = StateIncreasing(); % Don't need to step this, wait one
            else
                % Too outside, spin until we find a direction that appears
                % to be inwards.
                c.uav.cmdTurn(6);
                c.uav.cmdSpeed(10);
                
                c.uav.updateState(c.dt);
                
                newState = state;
            end
        end
    end
    
end

