classdef StateInside < handle
    %STATEINSIDE Cloud has grown or moved to surround us, need to escape
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function state = StateInside()
            
        end
        function newState = step(state, t, c)
            [~, ppm] = c.getInput(t);
            
            if ppm < c.prevPPM
                % Are moving outside, keep going straight for a step.
                c.uav.cmdTurn(0);
                c.uav.cmdSpeed(10);
                
                c.uav.updateState(c.dt);
                
                newState = StateLost(); % Don't need to step this, wait one
            else
                % Too inside, spin until we find a direction that appears
                % to be outwards.
                c.uav.cmdTurn(6);
                c.uav.cmdSpeed(10);
                
                c.uav.updateState(c.dt);
                
                newState = state;
            end
        end
    end
    
end

