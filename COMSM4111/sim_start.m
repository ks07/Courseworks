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

% Set initial state
for i = 1:uav_count
    ctrl(i) = Controller(i,dt,cloud,net,plotter);
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