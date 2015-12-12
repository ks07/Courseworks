classdef Controller < handle
    %CONTROLLER The actual decision making code for the robot
    
    properties
        dt;     % The size of timesteps.
        uav;	% The actual UAV we are controlling.
        cloud;	% The cloud to track.
        POS_BOUND = 1000;	% Max distance in any direction.
        PPM_BOUND = 1;  % PPM that signifies the desired boundary.
    end
    
    methods
        function ctrl = Controller(dt,cloud)
            ctrl.dt = dt;
            ctrl.uav = UAV([0 0],0);
            ctrl.cloud = cloud;
        end
        function step(self,t)
            [gps, ppm] = self.uav.getInput(self.cloud,t);
            
            if self.checkBounds(gps)
                disp('Oops, too far!');
            elseif ppm >= self.PPM_BOUND
                disp('found cloud');
            else
                self.uav.cmdTurn(rand() * 12 - 6);
                self.uav.cmdSpeed(rand() * 10 + 10);
            end
            
            self.uav.updateState();
            self.uav.plot(self.cloud,t);
        end
        function ok = checkBounds(self,gps)
            ok = max(gps) >= self.POS_BOUND;
        end
    end
    
end

