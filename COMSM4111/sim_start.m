function sim_start
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
t = 1300;
%dt = 3.6;
dt = 1.5;
% open new figure window
figure(1);
clf;
hold on % so each plot doesn't wipe the predecessor

uav_count = 10;

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
    ctrl(i) = Controller(i,[sx,sy],rad2deg(sa),dt,cloud,net,plotter);
end


% main simulation loop, run for 30 minutes
for kk=1:(30*60/dt),
    
    % time
    t = t + dt;
    
    for i = 1:uav_count
        ctrl(i).step(t);
    end
    
    net.step();
    plotter.draw(t,cloud,true);
    
    % pause ensures that the plots update
    pause(0.0025)
    
end