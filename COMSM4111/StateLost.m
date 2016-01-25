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
                msgs = double(c.uav.comm_rx(Network.TYPE_FOUND));

                c.uav.cmdTurn(0.1);
                c.uav.cmdSpeed(20);

                c.uav.updateState(c.dt);

                if ~isempty(msgs)
                    % Pick a random found target and try heading towards
                    % it.
                    i = randi(size(msgs,1));
                    newState = StateTarget(msgs(i,2:3));
                end
            end
        end
    end
    
end

