classdef Controller < handle
    %CONTROLLER The actual decision making code for the robot
    
    properties
        dt;     % The size of timesteps.
        uav;	% The actual UAV we are controlling.
        cloud;	% The cloud to track.
        prevGPS;    % The previously recorded GPS position.
        prevPPM;    % The previously recorded PPM.
        state;
        net; % Should this be in UAV? todo
        
        inside_measures; % Stores last 4 measurements in inside state.
        state_ctr;
        prevState;
        prevTurn;
        prevSpeed;
        
        target;
        
        PPM_UPPER;
        PPM_LOWER;
        
        statehex;
    end
    
    properties (Constant)
        STATE_LOST = 0; % Not in cloud
        STATE_INCREASING = 1; % Detected moving towards cloud
        STATE_FOUND = 2; % At approx 1ppm boundary
        STATE_LEAVING = 3; % Leaving map bounds
        STATE_RETURNING = 4; % Just made a turn after leaving
        STATE_INSIDE = 5; % Too far into cloud
        
        STATE_FOLLOW = 10;  % Maybe on contour line
        STATE_HIGH_LEFT_0 = 11; 
        STATE_HIGH_RIGHT_0 = 12;
        STATE_LOW_LEFT_0 = 13;
        STATE_LOW_RIGHT_0 = 14;
        STATE_HIGH_LEFT_1 = 15; 
        STATE_HIGH_RIGHT_1 = 16;
        STATE_LOW_LEFT_1 = 17;
        STATE_LOW_RIGHT_1 = 18;
        STATE_HIGH_LEFT_A = 19;
        STATE_HIGH_RIGHT_A = 20;
        STATE_LOW_LEFT_A = 21;
        STATE_LOW_RIGHT_A = 22;
        
        STATE_T_LOST = 50;
        
        STATE_DECIDE_INIT = 100;
        STATE_DECIDE_LEFT = 110;
        STATE_DECIDE_MID = 120;
        STATE_DECIDE_RIGHT = 130;
        STATE_DECIDE_BACK = 140;
        STATE_DECIDE_OUTCOME = 150;
        
        POS_BOUND = 800;%1000;	% Max distance in any direction.
        PPM_BOUND = 1;  % PPM that signifies the desired boundary.
    end
    
    methods
        function ctrl = Controller(dt,cloud,colour,net)
            ctrl.dt = dt;
            %ctrl.uav = UAV(normrnd(0,3,1,2), rand() * 360, colour);
            %ctrl.uav = UAV(normrnd(0,150,1,2), rand() * 360, colour);
            ctrl.uav = UAV([560 218], 10, colour);
            ctrl.cloud = cloud;
            ctrl.prevGPS = [0 0];
            ctrl.prevPPM = 0;
            ctrl.state = ctrl.STATE_DECIDE_INIT;
            ctrl.state_ctr = 0;
            ctrl.net = net;
            ctrl.target = rand(1,2) * ctrl.POS_BOUND * 2 - ctrl.POS_BOUND;
            
            ppm_pcnt = 0.1;
            ctrl.PPM_LOWER = ctrl.PPM_BOUND * (1 - ppm_pcnt);
            ctrl.PPM_UPPER = ctrl.PPM_BOUND * (1 + ppm_pcnt);
            
            ctrl.statehex = StateHex();
        end
        function step(self,t,mapDraw)
            [gps, ppm] = self.uav.getInput(self.cloud,t);
            
            disp('state');
            disp(self.state);
            
            disp('go go go statehex');
            self.statehex = self.statehex.step(t,self);
            
             %self.uav.updateState(self.dt);
             %self.uav.plot(self.cloud,t,mapDraw);
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
        function d = dist(self, p, q)
            d = pdist([p;q]);
        end
        function [spd, trn] = calcTurn(self, angle)
            trn = sign(angle) * 6;
            spd = angle / trn / self.dt;
        end
    end
    
end

