function [foundout,ppmout,stat_ppm_leg_count_time,stat_hull_time] = sim_start(uav_count)
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
cloud_start_time = 0;
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

iter = 1;
stat_ppm_now = zeros(uav_count,1);
stat_ppm_avg_time = zeros((30*60/dt),4);
stat_ppm_leg_count_time = zeros((30*60/dt),6);

stat_hull_time = zeros((30*60/dt),2); % time, expanded range


% main simulation loop, run for 30 minutes
for kk=1:(30*60/dt),
    
    % time
    t = t + dt;
    
    stat = [-0.8,-0.9,-1.1,-1.2,-2]; % Mistakes were made, now legacy reasons.
    expanded_range = [];
    
    for i = 1:uav_count
        ctrl(i).step(t - cloud_start_time); % UAV needs relative time (to start time)
        stat_ppm_now(i) = ctrl(i).prevPPM;
        if ctrl(i).prevPPM < 0.8
            stat(1) = stat(1) + 1;
        elseif ctrl(i).prevPPM < 0.9
            stat(2) = stat(2) + 1;
            expanded_range(end+1,:) = ctrl(i).prevGPS;
        elseif ctrl(i).prevPPM > 1.2
            stat(5) = stat(5) + 1;
            expanded_range(end+1,:) = ctrl(i).prevGPS;
        elseif ctrl(i).prevPPM > 1.1
            stat(4) = stat(4) + 1;
            expanded_range(end+1,:) = ctrl(i).prevGPS;
        else
            stat(3) = stat(3) + 1;
            expanded_range(end+1,:) = ctrl(i).prevGPS;
        end
    end
    
    stat_ppm_avg_time(iter,:) = [t,mean(stat_ppm_now),median(stat_ppm_now),std(stat_ppm_now)];
    stat_ppm_leg_count_time(iter,:) = [t,stat];

    
    
    net.step();
    cloudpoints = plotter.draw(t,cloud,true); % Plotter needs real time
    
    % find convex hull.
    try
        stat_hull_time(iter,1) = t;
        [cx,cy]=poly2cw(cloudpoints(1,2:end)',cloudpoints(2,2:end)');
        carea = polyarea(cx,cy);
        
        if carea > 0
            edronex = expanded_range(:,1);
            edroney = expanded_range(:,2);
            ipick = convhull(edronex,edroney);
            [x,y]=poly2cw(edronex(ipick),edroney(ipick));
            [ix,iy]=polybool('&',x,y,cx,cy);
            plot(ix,iy,'m');
            eiarea = polyarea(ix,iy);
            stat_hull_time(iter,2) = eiarea / carea;
        end
    end
    
    % pause ensures that the plots update
    %pause(0.0025)
    drawnow;
    
    iter = iter + 1;
end

foundout = zeros(1,i);
for i = 1:uav_count
    foundout(i) = ctrl(i).stat_state_found;
end
ppmout = stat_ppm_avg_time;
disp('done');