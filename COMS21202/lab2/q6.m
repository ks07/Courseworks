function [x, p] = q6(N,theta)
    a = theta;
    p = [];
    x = (0:N)';
    for k = 0 : N
        p = [p ; nchoosek(N, k) * a^k * (1-a)^(N-k)];
    end
end

