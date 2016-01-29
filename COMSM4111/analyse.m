found_mnmdsd = [];
ppm_tmnmdsd = [];
legs = [];
hulls = [];
colls_oob = [];
for i=[10,25,40]%,55]
    i
    uav_count = mod(i-1,15)+1
    [uav_state_founds, ppmout,legcount,hullpcnt,colls,oob] = sim_start(uav_count);
    found_mnmdsd(i,:) = [mean(uav_state_founds), median(uav_state_founds), std(uav_state_founds)];
    ppm_tmnmdsd(i,:,:) = ppmout;
    legs(i,:,:) = legcount;
    hulls(i,:,:) = hullpcnt;
    colls_oob(i,:,:) = [colls,oob];
end


% %% SOME COLLISION STATS STUFF
% valids = [10,25,40]%,55]
% mean(mean(hulls(valids,800:end,:),2))
% mean(colls_oob(valids,:,:),1)
% median(colls_oob([10,25,40],:,:),1)