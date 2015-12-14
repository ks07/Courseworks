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
        function updateState(self,dt)
            % Lol, runge-kutta is for nerds (as is euler)
            state = [self.pos, self.hdg];
            input = [self.spd, self.trn];
            newstate = self.pos_rk4(state,input,dt);
            self.pos = newstate(1:2);
            self.hdg = newstate(3);
        end
        function newstate=pos_rk4(self,state,input,dt)
            % Runge-Kutta 4th order for position
            k1 = self.state_f_(state,input);
            k2 = self.state_f_(state+k1*dt/2,input);
            k3 = self.state_f_(state+k2*dt/2,input);
            k4 = self.state_f_(state+k3*dt,input);
            newstate = state+(k1+2*k2+2*k3+k4)*dt/6;
        end
        function state_=state_f_(self,state,input)
            % UAV dynamics
            x_ = input(1) * sind(state(3));
            y_ = input(1) * cosd(state(3));
            theta_ = input(1) * input(2);
            state_ = [x_, y_, theta_];
        end
        function plot(self, cloud, t)
            % put information in the title
            ppm = cloudsamp(cloud,self.pos(1),self.pos(2),t);
            title(sprintf('t=%.1f secs pos=(%.1f, %.1f)  Concentration=%.2f',t, self.pos(1),self.pos(2),ppm))
            plot(self.pos(1),self.pos(2),'o');
            % plot the cloud contours
            cloudplot(cloud,t)
        end
    end
    
end

