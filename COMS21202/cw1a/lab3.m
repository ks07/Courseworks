clearvars

% Q1
traingf = load('gf12815.train')
trainap = load('ap12750.train')

% ap 5,3 gf 5,1

% 3 classes
Xap = [trainap(:,5), trainap(:,3)]
Xgf = [traingf(:,5), traingf(:,1)]

% Q2
[cidxgf, ctrsgf] = kmeans(Xgf, 3)
[cidxap, ctrsap] = kmeans(Xap, 3)

gfFound1 = find(cidxgf == 1)
gfFound2 = find(cidxgf == 2)
gfFound3 = find(cidxgf == 3)

apFound1 = find(cidxap == 1)
apFound2 = find(cidxap == 2)
apFound3 = find(cidxap == 3)

gfC1 = Xgf(gfFound1',:)
gfC2 = Xgf(gfFound2',:)
gfC3 = Xgf(gfFound3',:)

apC1 = Xap(apFound1',:)
apC2 = Xap(apFound2',:)
apC3 = Xap(apFound3',:)

% Scatter plot the three classes for each
figure(1)
hold off
scatter(apC1(:,1), apC1(:,2), 50, 'rx')
hold on
scatter(apC2(:,1), apC2(:,2), 50, 'bx')
scatter(apC3(:,1), apC3(:,2), 50, 'gx')

figure(2)
hold off
scatter(gfC1(:,1), gfC1(:,2), 50, 'rx')
hold on
scatter(gfC2(:,1), gfC2(:,2), 50, 'bx')
scatter(gfC3(:,1), gfC3(:,2), 50, 'gx')

% Q3
testgf = load('gf12815.test')
testap = load('ap12750.test')

testXap = [testap(:,5), testap(:,3)]
testXgf = [testgf(:,5), testgf(:,1)]

testapDists = pdist2(testXap, ctrsap)
testgfDists = pdist2(testXgf, ctrsgf)

% don't care about Y
[Y,apCidx] = min(testapDists, [], 2)
[Y,gfCidx] = min(testgfDists, [], 2)


apTestFound1 = find(apCidx == 1)
apTestFound2 = find(apCidx == 2)
apTestFound3 = find(apCidx == 3)

gfTestFound1 = find(gfCidx == 1)
gfTestFound2 = find(gfCidx == 2)
gfTestFound3 = find(gfCidx == 3)

gfTestC1 = testXgf(gfTestFound1',:)
gfTestC2 = testXgf(gfTestFound2',:)
gfTestC3 = testXgf(gfTestFound3',:)

apTestC1 = testXap(apTestFound1',:)
apTestC2 = testXap(apTestFound2',:)
apTestC3 = testXap(apTestFound3',:)

figure(1)
hold on
scatter(apTestC1(:,1), apTestC1(:,2), 50, 'ro')
scatter(apTestC2(:,1), apTestC2(:,2), 50, 'bo')
scatter(apTestC3(:,1), apTestC3(:,2), 50, 'go')

%voronoi(ctrsap(:,1), ctrsap(:,2))

figure(2)
hold on
scatter(gfTestC1(:,1), gfTestC1(:,2), 50, 'ro')
scatter(gfTestC2(:,1), gfTestC2(:,2), 50, 'bo')
scatter(gfTestC3(:,1), gfTestC3(:,2), 50, 'go')

%voronoi(ctrsgf(:,1), ctrsgf(:,2))

% Q4
[errcidxap, errctrsap, E] = kmeans(Xap, 3);
D =[0];
while (sum(D) <= sum(E))
[errcidxap, errctrsap, D] = kmeans(Xap, 3);
end

figure(1)
hold on
voronoi(errctrsap(:,1), errctrsap(:,2))


[errcidxgf, errctrsgf, Egf] = kmeans(Xgf, 3, 'distance','cityblock');
Dgf =[0];
while (sum(Dgf) <= sum(Egf))
[errcidxgf, errctrsgf, Dgf] = kmeans(Xgf, 3, 'distance','cityblock');
end

figure(2)
hold on
voronoi(errctrsgf(:,1), errctrsgf(:,2))