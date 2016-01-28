% dirty combo, only takes 3 5 7 8 10 14 UAV data, shoves it in a massive
% table.
flathull = cat(2,squeeze(hulls(3,:,:)),squeeze(hulls(5,:,2))',squeeze(hulls(7,:,2))',squeeze(hulls(8,:,2))',squeeze(hulls(10,:,2))',squeeze(hulls(14,:,2))');
xlswrite('excelout\hulls_all.xlsx',flathull,1);

% Do the moving average in advance, less effort than excel
for i=1:size(flathull,2)
    maflathull(:,i) = conv(flathull(:,i), ones(1,12), 'valid'); % 12 point moving average for all columns
end
maflathull = maflathull / 12;
xlswrite('excelout\hulls_all.xlsx',maflathull,2);