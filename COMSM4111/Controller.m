classdef Controller < handle
    %CONTROLLER The actual decision making code for the robot
    
    properties
        dt;     % The size of timesteps.
        uav;	% The actual UAV we are controlling.
        cloud;	% The cloud to track.
        prevGPS;    % The previously recorded GPS position.
        prevPPM;    % The previously recorded PPM.
        state;
        
        inside_measures; % Stores last 4 measurements in inside state.
        state_ctr;
        prevState;
        
        PPM_UPPER;
        PPM_LOWER;
    end
    
    properties (Constant)
        STATE_LOST = 0; % Not in cloud
        STATE_INCREASING = 1; % Detected moving towards cloud
        STATE_FOUND = 2; % At approx 1ppm boundary
        STATE_LEAVING = 3; % Leaving map bounds
        STATE_RETURNING = 4; % Just made a turn after leaving
        STATE_INSIDE = 5; % Too far into cloud
        
        STATE_FOLLOW = 10;  % Maybe on contour line
        STATE_VEERING_LEFT = 11; 
        STATE_VEERING_RIGHT = 12;
        
        POS_BOUND = 800;%1000;	% Max distance in any direction.
        PPM_BOUND = 1;  % PPM that signifies the desired boundary.
    end
    
    methods
        function ctrl = Controller(dt,cloud,colour)
            ctrl.dt = dt;
            %ctrl.uav = UAV(normrnd(0,3,1,2), rand() * 360, colour);
            ctrl.uav = UAV([200 300], 45, colour);
            ctrl.cloud = cloud;
            ctrl.prevGPS = [0 0];
            ctrl.prevPPM = 0;
            ctrl.state = ctrl.STATE_FOLLOW;
            ctrl.state_ctr = 0;
            
            ppm_pcnt = 0.1;
            ctrl.PPM_LOWER = ctrl.PPM_BOUND * (1 - ppm_pcnt);
            ctrl.PPM_UPPER = ctrl.PPM_BOUND * (1 + ppm_pcnt);
        end
        function step(self,t,mapDraw)
            [gps, ppm] = self.uav.getInput(self.cloud,t);
            
            ppmo = ppm;
            if isnan(ppm)
                ppm = 0;
            end
            
%             self.estimateHeading(gps);
            
            self.prevState = self.state;
            
            % State transition function(s)
%             if self.state == self.STATE_INSIDE
%                 
%             elseif self.state == self.STATE_FOUND && self.state_ctr < 4
%                 disp('counting up');
%                 self.state_ctr = self.state_ctr + 1;
%                 self.inside_measures = [self.inside_measures ppm];
%             elseif ppm >= self.PPM_LOWER && ppm <= self.PPM_UPPER
%                 disp('in bounds')
%                 self.state_ctr = 0;
%                 self.state = self.STATE_FOUND;
%                 self.inside_measures = ppm;
%             elseif self.state == self.STATE_FOUND
%                 avg_ppm = mean(self.inside_measures);
%                 if avg_ppm > self.PPM_UPPER
%                     self.state = self.STATE_INSIDE;
%                 end
%             elseif ppm > self.PPM_UPPER
%                 self.state = self.STATE_INSIDE;
%             elseif self.state == self.STATE_LEAVING
%                 self.state = self.STATE_RETURNING;
%             elseif ~self.checkBounds(gps)
%                 self.state = self.STATE_LEAVING;
%             elseif ppm > self.prevPPM
%                 self.state = self.STATE_INCREASING;
%             else
%                 self.state = self.STATE_LOST;
%             end

            if ppm <= 0.9
                self.state = self.STATE_VEERING_LEFT;
            elseif ppm >= 1.1
                self.state = self.STATE_VEERING_RIGHT;
            else
                self.state = self.STATE_FOLLOW;
            end
            
            % Perform state operations
            switch self.state
                case self.STATE_LOST
                    disp('Searching for cloud...');
                    self.uav.cmdTurn(0.1);
                    self.uav.cmdSpeed(20);
                case self.STATE_INCREASING
                    disp('ppm increasing');
                    self.uav.cmdTurn(0);
                    self.uav.cmdSpeed(10);
                case self.STATE_FOUND
                    disp('found cloud');
                    self.uav.cmdTurn(6);
                    self.uav.cmdSpeed(10);
                case self.STATE_LEAVING
                    disp('moving out of bounds');
                    self.uav.cmdTurn(-1);
                    self.uav.cmdSpeed(20);
                case self.STATE_RETURNING
                    disp('moving away from boundary');
                    self.uav.cmdTurn(-0.1);
                    self.uav.cmdSpeed(20);
                case self.STATE_INSIDE
                    disp('too far inside');
                    if self.prevPPM > ppm
                        self.uav.cmdTurn(0);
                        self.uav.cmdSpeed(10);
                        self.state = self.STATE_LOST;
                    end
                case self.STATE_FOLLOW
                    disp('folo')
                    self.uav.cmdTurn(0);
                    self.uav.cmdSpeed(10);
                case self.STATE_VEERING_LEFT
                    disp('need to go right gov')
                    
                    dist = 1 - ppm;
                    turn = dist * 2;
                    
                    if self.prevState == self.STATE_VEERING_LEFT
                        turn = 0;
                        self.state = self.STATE_FOLLOW;
                    end
                    
                    self.uav.cmdTurn(turn);
                    self.uav.cmdSpeed(10);
                case self.STATE_VEERING_RIGHT
                    disp('need to go left bruv')
                    
                    dist = ppm - 1;
                    turn = dist * -2;
                    
                    if self.prevState == self.STATE_VEERING_RIGHT
                        turn = 0;
                        self.state = self.STATE_FOLLOW;
                    end
                    
                    self.uav.cmdTurn(turn);
                    self.uav.cmdSpeed(10);
            end
            
            self.uav.updateState(self.dt);
            self.uav.plot(self.cloud,t,mapDraw);
            
            % Update records.
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
    end
    
end

