function sim_start
%
% simulation example for use of cloud dispersion model
%
% Arthur Richards, Nov 2014
%

% load cloud data
% choose a scenario
 load 'cloud1.mat'
%load 'cloud2.mat'

% time and time step
t = 1300;
%dt = 3.6;
dt = 1.5;
% open new figure window
figure(1);
clf;
hold on % so each plot doesn't wipe the predecessor

uav_count = 50;

colour = [0 1 1];
cstep = 1 / uav_count;

net = Network();

% Set initial state
for i = 1:uav_count
    ctrl(i) = Controller(dt,cloud,hsv2rgb(colour),net);
    colour(1) = colour(1) + cstep;
end


% main simulation loop
for kk=1:1000,
    
    % time
    t = t + dt;
    
    % clear the axes for fresh plotting
    %cla;
    
    for i = 1:uav_count
        ctrl(i).step(t, i == 1);
    end
    
    net.step();
    
    % pause ensures that the plots update
    pause(0.025)
    
end