clearvars;

%Load the data
% ap 5,3 gf 5,1
train = load('ap12750.train');
test = load('ap12750.test');
data = [train(:,5), train(:,3)];
testPoints = [test(:,5), test(:,3)];

% train = load('gf12815.train');
% test = load('gf12815.test')
% data = [train(:,5), train(:,1)];
% testPoints = [test(:,5), test(:,1)]

% Run k-means
[cidx, ctrs] = kmeans(data, 3);

% Group clusters into matrices
found1 = find(cidx == 1);
found2 = find(cidx == 2);
found3 = find(cidx == 3);

c1 = data(found1',:);
c2 = data(found2',:);
c3 = data(found3',:);

% Calculate the mean and covariance of all clusters
mC1 = mean(c1);
mC2 = mean(c2);
mC3 = mean(c3);

cC1 = cov(c1);
cC2 = cov(c2);
cC3 = cov(c3);

%For question 3, set the covariance equal to zero
% cC1 = eye(2);
% cC2 = eye(2);
% cC3 = eye(2);


% Scatter plot the three classes for each
figure(1)
hold off
scatter(c1(:,1), c1(:,2), 50, 'rx')
hold on
scatter(c2(:,1), c2(:,2), 50, 'bx')
scatter(c3(:,1), c3(:,2), 50, 'gx')

% Scatter plot the test points
scatter(testPoints(:,1), testPoints(:,2), 50, 'mo')

% Calculate the meshgrid
xAxis = 0:0.01:9;
yAxis = 0:0.01:9.5;

[xMesh, yMesh] = meshgrid(xAxis,yAxis);

zC1 = mvnpdf([xMesh(:) yMesh(:)], mC1, cC1);
zC1 = reshape(zC1, size(xMesh));

zC2 = mvnpdf([xMesh(:) yMesh(:)], mC2, cC2);
zC2 = reshape(zC2, size(xMesh));

zC3 = mvnpdf([xMesh(:) yMesh(:)], mC3, cC3);
zC3 = reshape(zC3, size(xMesh));

% Calculate the contour level to be 95%
pC1 = (1/(2*pi*sqrt(det(cC1))))*exp(-3);
pC2 = (1/(2*pi*sqrt(det(cC2))))*exp(-3);
pC3 = (1/(2*pi*sqrt(det(cC3))))*exp(-3);

% Plot the contour
figure(1)
contour(xMesh,yMesh,zC1,pC1);
contour(xMesh,yMesh,zC2,pC2);
contour(xMesh,yMesh,zC3,pC3);


% Calculate the decision boundary
LRC1 = (zC1 ./ zC2);
LRC2 = (zC1 ./ zC3);
LRC3 = (zC2 ./ zC3);
% LRC1 = (zC1 ./ (zC2 + zC3));
% LRC2 = (zC2 ./ (zC1 + zC3));

% contour(xMesh,yMesh,LRC1,[2 2]);
% contour(xMesh,yMesh,LRC2,[2 2]);
contour(xMesh,yMesh,LRC1,[1 1]);
contour(xMesh,yMesh,LRC2,[1 1]);
contour(xMesh,yMesh,LRC3,[1 1]);

% Plot the nearest-centroid classifier
voronoi(ctrs(:,1),ctrs(:,2));