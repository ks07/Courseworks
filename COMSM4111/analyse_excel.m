for i=1:15
    legprops = squeeze(legs(i,:,:));
    legprops(:,2:6) = legprops(:,2:6) - repmat([-0.8,-0.9,-1.1,-1.2,-2],size(legprops,1),1); % Need to offset, mistakes were made.
    for j=1:size(legprops,2)
        malegprops(:,j) = conv(legprops(:,j), ones(1,12), 'valid'); % 12 point moving average for all columns
    end
    malegprops = malegprops / 12; % calc said average from sums
    xlswrite('excelout\malegprops_all.xlsx',malegprops,i); % Write to sheet in excel.
end
