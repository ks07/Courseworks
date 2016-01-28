found_mnmdsd = [];
ppm_tmnmdsd = [];
legs = [];
hulls = [];
for i=[3,5,7,8,10,14]
    i
    uav_count = mod(i-1,15)+1
    [uav_state_founds, ppmout,legcount,hullpcnt] = sim_start(uav_count);
    found_mnmdsd(i,:) = [mean(uav_state_founds), median(uav_state_founds), std(uav_state_founds)];
    ppm_tmnmdsd(i,:,:) = ppmout;
    legs(i,:,:) = legcount;
    hulls(i,:,:) = hullpcnt;
end