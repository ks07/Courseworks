% q2 Sample 100 points, do ML fitting
[x y] = questTwo(100,0.4,0.1,0,1);
ml1 = dot(x,y);
ml2 = dot(x,x);
q2Ans = ml1/ml2
clearvars


% q3
a = [];
for i = 1 : 500
    [x y] = questTwo(100,0.4,0.1,0,1);
    ml1 = dot(x,y);
    ml2 = dot(x,x);
    a = [a; ml1/ml2];
end
q3Ans = var(a)
clearvars

%q4
a = [];
for i = 1 : 500
    [x y] = questTwo(100,0.4,0.1,9,10);
    ml1 = dot(x,y);
    ml2 = dot(x,x);
    a = [a; ml1/ml2];
end
q4Ans = var(a)

%q5
[x y] = questTwo(100,0.4,0.1,9,10);
q5Ans = 0.1 / dot(x,x)
clearvars

%q6 & q7
[x p] = q6(20, 0.4);
plot(x,p);
