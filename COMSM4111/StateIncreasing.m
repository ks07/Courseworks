classdef StateIncreasing < handle
    %STATEINCREASING When PPM is increasing, and not high enough yet.
    %   Detailed explanation goes here
    
    properties
        PPM_LOWER;
        PPM_UPPER;
    end
    
    methods
        function state = StateIncreasing()
            state.PPM_LOWER = 0.9;
            state.PPM_UPPER = 1.1;
        end
        function newState = step(state, t, c)
            newState = state;
            [~, ppm] = c.getInput(t);
            
            if ppm >= state.PPM_LOWER && ppm <= state.PPM_UPPER
                % Have reached the cloud boundary.
                newState = StateHex();
                newState = newState.step(t,c);
            elseif ppm > c.prevPPM
                c.uav.cmdTurn(0);
                c.uav.cmdSpeed(10);
            
                c.uav.updateState(c.dt);
            elseif ppm > state.PPM_UPPER
                % Have reached the cloud boundary.
                newState = StateInside();
                newState = newState.step(t,c);
            else
                % No longer increasing, go back to lost state.
                newState = StateLost();
                c.uav.updateState(c.dt);
                %newState = newState.step(t,c);
            end
        end
    end
    
end
