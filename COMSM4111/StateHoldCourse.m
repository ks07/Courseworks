classdef StateHoldCourse < handle
    %STATEHEX State to try and follow the predicted boundary trajectory (2)
    
    properties
        ctr;
        lim;
        spd;
        hexbrake;
    end
    
    methods
        function state = StateHoldCourse(holdfor,hexbrake)
            state.ctr = 0;
            state.lim = holdfor;
            state.spd = 20;
            state.hexbrake = hexbrake; % If true, break if the ppm gets near 1.
        end
        function newState = step(state, t, c)
            [~,ppm] = c.getInput(t);
            ppmlobound = 1.05; % When to brake, if enabled.
            ppmhibound = 1.80; % When to brake, if enabled.
            newState = state;
            if state.hexbrake && ppm < ppmlobound
                % Done!
                disp('emergency stop');
                newState = StateHex();
                newState = newState.step(t,c);
                return
            elseif state.hexbrake && ppm > ppmhibound
                % Done!
                disp('emergency stop');
                newState = StateHex();
                newState = newState.step(t,c);
                return
            elseif state.ctr < state.lim
                % Keep travelling
                c.uav.cmdTurn(0);
                c.uav.cmdSpeed(state.spd);
                state.ctr = state.ctr + 1;
            
                c.uav.updateState(c.dt);
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
