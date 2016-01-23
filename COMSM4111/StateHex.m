classdef StateHex < handle
    %STATEHEX Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        ctr;
        measures;
        points;
    end
    
    methods
        function state = StateHex()
            state.ctr = 0;
            state.measures = zeros(6,1);
            state.points = zeros(6,2);
        end
        function newState = step(state, t, c)
            
            if state.ctr == 0
                % Turn left to open the hex.
                c.uav.cmdTurn(-4);
                c.uav.cmdSpeed(10);
                
                c.uav.updateState(c.dt);
                c.uav.plot(c.cloud,t,true);
                [gps,ppm] = c.uav.getInput(c.cloud, t);
                
                state.ctr = 1;
                state.measures(state.ctr) = ppm;
                state.points(state.ctr,:) = gps;
                
                newState = state;
            elseif state.ctr < 6
                % Turn right and measure 5 times.
                c.uav.cmdTurn(4);
                c.uav.cmdSpeed(10);
                
                c.uav.updateState(c.dt);
                c.uav.plot(c.cloud,t,true);
                [gps,ppm] = c.uav.getInput(c.cloud, t);
                
                state.ctr = state.ctr + 1;
                if state.ctr <= 6
                    state.measures(state.ctr) = ppm;
                    state.points(state.ctr,:) = gps;
                end
                
                newState = state;
            else
                % Make a decision
                on = find(state.measures == 1);
                edges = [];
                for i = 1:6
                    a = state.measures(i);
                    b = state.measures(mod(i,6)+1);
                    ap = state.points(i,:);
                    bp = state.points(mod(i,6)+1,:);
                    if min(a,b) < 1 && max(a,b) > 1 || (a == 1 && b == 1)
                        midpoint = (ap + bp) / 2;
                        edges = [edges; i midpoint];
                    elseif a == 1
                        edges = [edges; i ap];
                    end
                end
                
                %Plot the chosen ones?
                plot(edges(:,2),edges(:,3));
                disp('wow');
            end
        end
    end
    
end

