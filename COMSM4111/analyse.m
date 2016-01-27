found_mnmdsd = [];
for i=1:15
    uav_state_founds = sim_start(i);
    found_mnmdsd(i,:) = [mean(uav_state_founds), median(uav_state_founds), std(uav_state_founds)];
end