function [] = getAV()
    a = [];
    for i = 1 : 500
        [x y] = questTwo(100,0.4,0.1,9,10);
        ml1 = dot(x,y);
        ml2 = dot(x,x);
        a = [a; ml1/ml2];
    end
    v = var(a)
end

