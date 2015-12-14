classdef Controller < handle
    %CONTROLLER The actual decision making code for the robot
    
    properties
        dt;     % The size of timesteps.
        uav;	% The actual UAV we are controlling.
        cloud;	% The cloud to track.
        prevGPS;    % The previously recorded GPS position.
        prevPPM;    % The previously recorded PPM.
        returning;  % Marks whether we are currently trying to get back
        cloudfound; % Marks whether we have found the cloud boundary.
        POS_BOUND = 800;%1000;	% Max distance in any direction.
        PPM_BOUND = 1;  % PPM that signifies the desired boundary.
    end
    
    methods
        function ctrl = Controller(dt,cloud)
            ctrl.dt = dt;
            ctrl.uav = UAV([0 0],90);
            ctrl.cloud = cloud;
            ctrl.prevGPS = [0 0];
            ctrl.prevPPM = 0;
            ctrl.returning = false;
            ctrl.cloudfound = false;
        end
        function step(self,t)
            [gps, ppm] = self.uav.getInput(self.cloud,t);
            
            self.estimateHeading(gps);
            
            if self.cloudfound
                disp('found cloud');
                self.uav.cmdTurn(6);
                self.uav.cmdSpeed(10);
            elseif self.checkBounds(gps)
                disp('Oops, too far!');
                if self.returning
                    self.uav.cmdTurn(-0.1);
                    self.uav.cmdSpeed(20);
                    self.returning = false;
                else
                    self.uav.cmdTurn(-1);
                    self.uav.cmdSpeed(20);
                    self.returning = true;
                end
            elseif ppm >= self.PPM_BOUND
                disp('found cloud');
                self.uav.cmdTurn(6);
                self.uav.cmdSpeed(10);
                self.returning = false;
                self.cloudfound = true;
            else
                self.uav.cmdTurn(0.1)
                self.uav.cmdSpeed(20);
                self.returning = false;
            end
            
            self.uav.updateState(self.dt);
            self.uav.plot(self.cloud,t);
            
            % Update records.
            self.prevGPS = gps;
            self.prevPPM = ppm;
        end
        function ok = checkBounds(self,gps)
            ok = max(abs(gps)) >= self.POS_BOUND;
        end
        function estHDG = estimateHeading(self,gps)
            %a = [gps 0];
            %b = [self.prevGPS 0];
            a = self.prevGPS - gps;
            b = [0 1];
            a = a / norm(a);
            b = b / norm(b);
            %estHDG = atan2(norm(cross(a,b)), dot(a,b))
            estHDG = acosd(a(:).'*b(:))
        end
    end
    
end

