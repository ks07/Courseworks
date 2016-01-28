for i=1:45
    %r = 3; % number of repeats of the experiment to use.
    legprops = squeeze(legs(i,:,:));
    legprops(:,2:end) = legprops(:,2:end) - repmat([-0.8,-0.9,-1.1,-1.2,-2],size(legprops,1),1); % Need to offset, mistakes were made.
    for j=1:size(legprops,2)
        malegprops(:,j,i) = conv(legprops(:,j), ones(1,12), 'valid'); % 12 point moving average for all columns
    end
    malegprops(:,:,i) = malegprops(:,:,i) / 12; % calc said average from sums
    %xlswrite('excelout\malegprops_all.xlsx',malegprops,i); % Write to sheet in excel.
end
% Average out the repeated tests
total = 45;
size = 15;
for i=1:size
    all = malegprops(:,:,i:size:total);
    maout = mean(all,3);
    xlswrite('excelout\malegprops_all_2.xlsx',maout,i);
end