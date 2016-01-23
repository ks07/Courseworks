classdef StateHoldCourse < handle
    
    properties
        ctr;
        lim;
        spd;
    end
    
    methods
        function state = StateHoldCourse(holdfor)
            state.ctr = 0;
            state.lim = holdfor;
            state.spd = 20;
        end
        function newState = step(state, t, c)
            newState = state;
            if state.ctr < state.lim
                % Keep travelling
                c.uav.cmdTurn(0);
                c.uav.cmdSpeed(state.spd);
                state.ctr = state.ctr + 1;
            
                c.uav.updateState(c.dt);
                c.uav.plot(c.cloud,t,true);
            else
                % Done!
                disp('held it in as long as I could');
                newState = StateHex();
                newState = newState.step(t,c);
                return
            end
        end
    end
    
end
