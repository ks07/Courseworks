found_mnmdsd = [];
ppm_tmnmdsd = [];
legs = [];
for i=1:60
    i
    uav_count = mod(i-1,15)+1
    [uav_state_founds, ppmout,legcount] = sim_start(uav_count);
    found_mnmdsd(i,:) = [mean(uav_state_founds), median(uav_state_founds), std(uav_state_founds)];
    ppm_tmnmdsd(i,:,:) = ppmout;
    legs(i,:,:) = legcount;
end