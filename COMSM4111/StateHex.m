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
            newState = state; % catch-all
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
                        edges = [edges; (i + 0.5) midpoint];
                    elseif a == 1
                        edges = [edges; i ap];
                    end
                end
                
                %Plot the chosen ones?
                plot(edges(:,2),edges(:,3));
                disp('wow');
                
                ppick = state.parallel_edge(edges(:,1));
                
                disp('okay');
                newState = StateHexDrive(ppick);
            end
        end
        function point = parallel_edge(state, point_nos)
            point_nos = mod(point_nos, 6); % Treat 6+ as 0s
            an = min(point_nos);
            bn = max(point_nos);
            diff = bn - an;
            %moddiff = (an + 6) - bn; % To check past the bounds!
            if diff == 1
                % This is the case where we've picked 2 midpoints with line
                % parallel to direction faced at endpoints (i.e. boundary
                % is either side of a single vertex)
                point = an + 0.5;
            elseif diff == 5
                % Same as the parallel case but crosses the 0 boundary,
                % i.e. when bn == 5.5, an == 0.5
                point = mod(bn + 0.5, 6);
            elseif diff == 3
                % point to opposite point, need to go to nearest and turn
                % half way extra (+30 deg)
                % OR
                % edge to opposite edge, need to go to halfway point
                point = an + 1.5;
            elseif diff == 2
                % midpoint to midpoint, covering 2 vertices on the nearest
                % side (e.g. 0.5 to 2.5) - need to take nearest + half
                % OR
                % point to point, single point between - go to it
                point = an + 1;
            elseif diff == 4
                % Same as diff == 2 case but for crossing 0 boundary
                point = mod(bn + 1, 6);
            end
        end
    end
    
end

