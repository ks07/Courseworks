function bivar(graphtype, mubass, sigmabass, musalmon, sigmasalmon)
% Call as:
%
% bivar(graphtype, [mubass, sigmabass, musalmon, sigmasalmon])
%
% Where graphtype is 2 for a 2D plot, or 3 for a 3D plot.
% Example: bivar(3, [4 3], [1 0 ; 0 1], [2 2], [1 0; 0 1])

% Default settings
if (nargin == 1)
    mubass = [4 3];
    %sigmabass = [1 0 ; 0 1];
    sigmabass = [1 0.75 ; 0.75 1];
    musalmon = [2 2];
    sigmasalmon = [1 0; 0 1];
end

Nbass = 100;
Nsalmon = 100;

% Generate distribution surface data
bass = mvnrnd(mubass,sigmabass,Nbass);
salmon = mvnrnd(musalmon,sigmasalmon,Nsalmon);
x = [0:0.1:10]';
y = [0:0.1:10]';

for i = 1:length(x)
    for (j = 1:length(y))
        Pbass(j,i) = getprob(x(i),y(j),mubass',sigmabass);
        Psalmon(j,i) = getprob(x(i),y(j),musalmon',sigmasalmon);
    end
end

Pb = (1/(2*pi*sqrt(det(sigmabass))))*exp(-1/2);
Ps = (1/(2*pi*sqrt(det(sigmasalmon))))*exp(-1/2);

LR = Pbass./Psalmon;

% Do the plotting
hold;
axis square;
if (graphtype == 2)
    % 2D scatter plots and standard deviation contours
    plot(bass(:,1),bass(:,2),'k.');
    plot(salmon(:,1),salmon(:,2),'r.');
    contour(x,y,Pbass,[Pb Pb],'k');
    contour(x,y,Psalmon,[Ps Ps],'k');
    contour(x,y,LR,[1 1],'g');
else
    % 3D surfaces and standard deviation contours
    surf(x,y,Pbass);
    surf(x,y,Psalmon);
    shading flat;
    contour3(x,y,Pbass,[Pb Pb],'k');
    contour3(x,y,Psalmon,[Ps Ps],'k');
    contour3(x,y,LR,[1 1],'g');
end


% Compute probability of (x,y) for a given mu and sigma
function P = getprob(x, y, mu, sigma)
    vec = [x y]';
    E = 2*pi * sqrt(det(sigma));
    P = (1/E) * exp(-((vec-mu)' * inv(sigma) * (vec-mu) / 2));
end

end % function bivar