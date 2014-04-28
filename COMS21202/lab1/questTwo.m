function [x,y] = questTwo(m, c, n)
    x = rand(n,1);
    e = normrnd(0,0.1,n,1);
    y = c + m * x + e;
    