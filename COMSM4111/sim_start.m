function sim_start
%
% simulation example for use of cloud dispersion model
%
% Arthur Richards, Nov 2014
%

% load cloud data
% choose a scenario
% load 'cloud1.mat'
load 'cloud2.mat'

% time and time step
t = 0;
dt = 3.6;

% open new figure window
figure(1)
hold on % so each plot doesn't wipe the predecessor

% Set initial state
ctrl = Controller(dt,cloud);

% main simulation loop
for kk=1:1000,
    
    % time
    t = t + dt;
    
    % clear the axes for fresh plotting
    cla
    
    ctrl.step(t);
    % cheat - robot goes round in circles
    %x = [500*cos(0.01*t); 500*sin(0.01*t)];
    
    
    % pause ensures that the plots update
    pause(0.1)
    
end