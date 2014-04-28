function [x,y] = questTwo(n, m, var, a, b)
    x = a + (b-a).*rand(n,1);
    e = normrnd(0,sqrt(var),n,1);
    y = m * x + e;
    