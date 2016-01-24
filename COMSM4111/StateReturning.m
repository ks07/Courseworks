classdef StateReturning
    %STATERETURNING Interrupt state, moving away from the range
    % limit.
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function state = StateReturning()
        end
        function newState = step(~, ~, c)
            % Hopefully moving away from the boundary.
            c.uav.cmdTurn(-0.1);
            c.uav.cmdSpeed(20);

            c.uav.updateState(c.dt);

            newState = StateLost(); % Most likely we will trigger leaving again.
        end
    end
    
end
