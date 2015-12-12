classdef UAV < handle
    %UAV Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = private,GetAccess = private)
        pos;    % Co-ordinates of the UAV
        hdg;    % Heading of the UAV
        spd;    % Commanded forward speed
        trn;    % Commanded turn curvature
    end
    
    methods
        function uav = UAV(start,hdg)
            uav.pos = start;
            uav.hdg = hdg;
            uav.spd = 0;
            uav.trn = 0;
        end
        function [gps, ppm] = getInput(self, cloud, t)
            gps = self.pos; % TODO: This needs error
            ppm = cloudsamp(cloud,self.pos(1),self.pos(2),t);
        end
        function cmdSpeed(self,spd)
            self.spd = spd;
        end
        function cmdTurn(self,trn)
            self.trn = trn;
        end
        function updateState(self)
            v = self.spd;
            mu = self.trn;
            theta = self.hdg;
            x_ = v * sind(theta);
            y_ = v * cosd(theta);
            theta_ = v * mu;
            
            % Lol, runge-kutta is for nerds (as is euler)
            self.pos = self.pos + [x_, y_];
            self.hdg = theta + theta_;
        end
        function plot(self, t, cloud)
            % put information in the title
            ppm = cloudsamp(cloud,self.pos(1),self.pos(2),t);
            title(sprintf('t=%.1f secs pos=(%.1f, %.1f)  Concentration=%.2f',t, self.pos(1),self.pos(2),ppm))
            plot(self.pos(1),self.pos(2),'o');
            % plot the cloud contours
            cloudplot(cloud,t)
        end
    end
    
end

