classdef StateFound < handle
    %STATEFOUND Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        ctr;
        ppm_measures;
    end
    
    properties(Constant)
        MEASURE_COUNT = 4;
        PPM_UPPER = 1.1;
        PPM_LOWER = 0.9;
    end
    
    methods
        function state = StateFound()
            state.ctr = 1;
            state.ppm_measures = zeros(state.MEASURE_COUNT,1);
        end
        function newState = step(state, t, c)
            newState = state;
            [gps, ppm] = c.getInput(t);
            
            %c.uav.comm_tx([Network.TYPE_FOUND,gps]);
            
            % On the boundary, hold position.
            c.uav.cmdTurn(6);
            c.uav.cmdSpeed(10);
            
            if state.ctr <= state.MEASURE_COUNT
                state.ppm_measures(state.ctr) = ppm;
                c.uav.updateState(c.dt);
                state.ctr = state.ctr + 1;
            else
                avg_ppm = mean(state.ppm_measures);
                if avg_ppm > state.PPM_UPPER
                    % The cloud has grown around us too much, need to move
                    % outwards
                    newState = StateInside();
                    newState = newState.step(t,c);
                elseif avg_ppm < state.PPM_LOWER
                    % The cloud has moved on.
                    newState = StateOutside();
                    newState = newState.step(t,c);
                else
                    % Still okay, hold.
                    
                    % 50% chance to enter hex mode?
                    if randi(2) == 2
                        newState = StateHex();
                        newState = newState.step(t,c);
                        return;
                    else
                        state.ctr = 1;
                        state.ppm_measures(:) = 0;
                        c.uav.updateState(c.dt);
                    end
                end
            end
        end
    end
    
end

