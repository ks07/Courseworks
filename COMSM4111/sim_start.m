function out = sim_start(uav_count)
%
% simulation example for use of cloud dispersion model
%
% Arthur Richards, Nov 2014
%

% load cloud data
% choose a scenario
%load 'cloud1.mat'
load 'cloud2.mat'

% time and time step
cloud_start_time = 0;%1300;
t = cloud_start_time;
%dt = 3.6;
dt = 1.5;
% open new figure window
figure(1);
clf;
hold on % so each plot doesn't wipe the predecessor

%uav_count = 1;

net = Network();
plotter = UAVPlotter(uav_count);

% Start UAVs spread in a circle facing outward.
START_RADIUS = 100;
START_ORIGIN = [0 0];

% Set initial state
for i = 1:uav_count
    sa = 2*pi*(i-1)/uav_count;
    sx = START_ORIGIN(1) + START_RADIUS * sin(sa); % This should be cos, but hdg is rotated 90 deg!
    sy = START_ORIGIN(2) + START_RADIUS * cos(sa);
    uav = UAV(i, normrnd([sx,sy],3), normrnd(rad2deg(sa),6), plotter, net, cloud, cloud_start_time);  % Give the offset, so ppm readings work
    ctrl(i) = Controller(uav,dt);
end


% main simulation loop, run for 30 minutes
for kk=1:(30*60/dt),
    
    % time
    t = t + dt;
    
    for i = 1:uav_count
        ctrl(i).step(t - cloud_start_time); % UAV needs relative time (to start time)
    end
    
    net.step();
    plotter.draw(t,cloud,true); % Plotter needs real time
    
    % pause ensures that the plots update
    %pause(0.0025)
    drawnow;
    
end

out = zeros(1,i);
for i = 1:uav_count
    out(i) = ctrl(i).stat_state_found;
end
disp('done');