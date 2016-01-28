classdef Controller < handle
    %CONTROLLER The actual decision making code for the robot
    
    properties
        dt;     % The size of timesteps.
        uav;	% The actual UAV we are controlling.
        prevGPS;    % The previously recorded GPS position.
        prevPPM;    % The previously recorded PPM.
        
        state;  % The state object to use to drive the UAV
        
        saved_timestamp; % The time the saved values were last updated.
        saved_gps; % The current (dep on timestamp) gps
        saved_ppm; % Ditto, for ppm.
        
        stat_state_found;
    end
    
    properties (Constant)
        POS_BOUND = 800;%1000;	% Max distance in any direction.
        PPM_BOUND = 1;  % PPM that signifies the desired boundary.
    end
    
    methods
        function ctrl = Controller(uav,dt)
            ctrl.dt = dt;

            ctrl.uav = uav;
            
            ctrl.prevGPS = [0 0];
            ctrl.prevPPM = 0;
            
            % Set starting state.
            %ctrl.state = StateHoldCourse(6,false);
            %ctrl.state = StateTarget([500 500]);
            ctrl.state = StateLost();
            ctrl.saved_timestamp = -1;
            
            ctrl.stat_state_found = 0;
        end
        function [gps, ppm] = getInput(self,t)
            % Wrapper so we can do extra processing if wanted
            % PPM calculation can be quite slow, so cache the result!
            if self.saved_timestamp ~= t
                self.saved_timestamp = t;
                [gps, ppm] = self.uav.getInput(t);
                self.saved_gps = gps;
                self.saved_ppm = ppm;
            else
               gps = self.saved_gps;
               ppm = self.saved_ppm;
            end
        end
        function step(self,t)
            [gps, ppm] = self.getInput(t);
            
            %Try sending a (really bad) estimated position?
            bgps = gps + (gps - self.prevGPS);
            
            % All UAVs broadcast their positions at/near start of timestep,
            % should give enough time to read the positions back in the
            % next timestep
            self.uav.comm_tx([Network.TYPE_COLLIDE,gps,bgps]);
            
            % Check for interrupts first.
            istate = StateInterruptLeaving.triggered(self.state,t,self,gps,ppm);
            if ~isequal(istate,false)
                self.state = istate;
            else
                istate = StateInterruptColliding.triggered(self.state,t,self,gps,ppm);
                if ~isequal(istate,false)
                    self.state = istate;
                end
            end
            
            if isa(self.state,'StateFound')
                self.stat_state_found = self.stat_state_found + 1;
            end
            self.state = self.state.step(t,self); %State step should inc
            
            self.prevGPS = gps;
            self.prevPPM = ppm;
        end
        function ok = checkBounds(self,gps)
            ok = max(abs(gps)) <= self.POS_BOUND;
        end
        function estHDG = estimateHeading(self,gps)
            %a = [gps 0];
            %b = [self.prevGPS 0];
            a = self.prevGPS - gps;
            b = [0 1];
            a = a / norm(a);
            b = b / norm(b);
            %estHDG = atan2(norm(cross(a,b)), dot(a,b))
            estHDG = acosd(a(:).'*b(:));
        end
        function d = dist(~, p, q)
            d = pdist([p;q]);
        end
        function [spd, trn] = calcTurn(self, angle)
            trn = sign(angle) * 6;
            spd = angle / trn / self.dt;
            if spd < 10
                spd = 10;
                trn = angle / (1.5 * spd);
            end
        end
    end
    
end

