classdef UAV < handle
    %UAV Summary of this class goes here
    %   Detailed explanation goes here
    
    properties %(SetAccess = private,GetAccess = private)
        id;     % Unique ID for UAV object, for debug and plotting.
        pos;    % Co-ordinates of the UAV
        hdg;    % Heading of the UAV
        spd;    % Commanded forward speed
        trn;    % Commanded turn curvature
        plotter;% Plotter object
        net;    % Network object
        cloud;	% The cloud to track.
    end
    
    methods
        function uav = UAV(id,start,hdg,plotter,net,cloud)
            uav.id = id; % Unique ID
            uav.pos = start;
            uav.hdg = hdg;
            uav.spd = 0;
            uav.trn = 0;
            uav.plotter = plotter;
            uav.net = net;
            uav.cloud = cloud;
        end
        function [gps, ppm] = getInput(self, t)
            % Model GPS error as normal distribution, sdev of 1.5m
            gps = normrnd(self.pos, [0.1 0.1]);%[1.5, 1.5]);
            % Can assume no error in ppm measure
            ppm = cloudsamp(self.cloud,self.pos(1),self.pos(2),t);
        end
        function cmdSpeed(self,spd)
            if spd < 10 || spd > 20
                error('Speed command out of range.');
            end
            self.spd = spd;
        end
        function cmdTurn(self,trn)
            if abs(trn) > 6
                error('Turn command out of range.');
            end
            self.trn = trn;
        end
        function updateState(self,dt)
            % Lol, runge-kutta is for nerds (as is euler)
            state = [self.pos, self.hdg];
            input = [self.spd, self.trn];
            newstate = self.pos_rk4(state,input,dt);
            self.pos = newstate(1:2);
            self.hdg = newstate(3);
            %disp('now at');
            %disp([self.pos, self.hdg]);
            
            self.plot();
        end
        function newstate=pos_rk4(self,state,input,dt)
            % Runge-Kutta 4th order for position
            k1 = self.state_f_(state,input);
            k2 = self.state_f_(state+k1*dt/2,input);
            k3 = self.state_f_(state+k2*dt/2,input);
            k4 = self.state_f_(state+k3*dt,input);
            newstate = state+(k1+2*k2+2*k3+k4)*dt/6;
        end
        function state_=state_f_(~,state,input)
            % UAV dynamics
            x_ = input(1) * sind(state(3));
            y_ = input(1) * cosd(state(3));
            theta_ = input(1) * input(2);
            state_ = [x_, y_, theta_];
        end
        function comm_tx(self,buff)
            % Send a message to all other UAVs.
            % buff is max 32 bytes, tx time is 1s
            self.net.tx(buff);
        end
        function msgs = comm_rx(self)
            % Receive all messages.
            msgs = self.net.rx();
        end
        function plot(self)
            self.plotter.plot(self.id, self.pos, self.hdg);
        end
    end
    
end

