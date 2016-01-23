classdef StateHexDrive < handle
    %STATEHEX Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        ctr;
        ppoint;
    end
    
    methods
        function state = StateHexDrive(ppoint)
            state.ctr = 0;
            state.ppoint = ppoint;
        end
        function newState = step(state, t, c)
            hexturn = 4;
            
            if state.ctr + 0.5 == state.ppoint
                % Half turn required this step then done.
                c.uav.cmdTurn(hexturn / 2);
                c.uav.cmdSpeed(10);
            elseif state.ctr >= state.ppoint
                % Done!
                disp('je suis finis');
                c.uav.cmdTurn(0);
                c.uav.cmdSpeed(20);
                %This should actually pass to a new state.
            else
                c.uav.cmdTurn(hexturn);
                c.uav.cmdSpeed(10);
            end
            
            c.uav.updateState(c.dt);
            c.uav.plot(c.cloud,t,true);
            state.ctr = state.ctr + 1;
            newState = state;
        end
    end
    
end

