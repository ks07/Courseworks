candidate_number(56626).

q1(assignment1_module:start_position_personal(P)).

q2a(new_pos(p(1,1),e,P)).

q2b(19).

q3([s,e,w,n]).

%% First deadend found is in fact the final cell
q4a([p(3, 3), p(3, 4), p(4, 4), p(4, 3), p(4, 2), p(3, 2), p(2, 2), p(2, 3), p(2, 4), p(1, 4), p(1, 3), p(1, 2), p(1, 1), p(2, 1), p(3, 1), p(4, 1)]).

%% Second deadend found is at (2,4) after backtracking to (2,3) -> (1,3)
q4b([p(3, 3), p(3, 4), p(4, 4), p(4, 3), p(4, 2), p(3, 2), p(2, 2), p(2, 3), p(2, 4), p(1, 4), p(1, 3), p(1, 2), p(1, 4), p(2, 4)).

%% First path == First deadend path
q4c([p(3, 3), p(3, 4), p(4, 4), p(4, 3), p(4, 2), p(3, 2), p(2, 2), p(2, 3), p(2, 4), p(1, 4), p(1, 3), p(1, 2), p(1, 1), p(2, 1), p(3, 1), p(4, 1)]).

%% Second path has a lot of backtracking
q4d([p(3, 3), p(3, 4), p(4, 4), p(4, 3), p(4, 2), p(4, 1), p(3, 1), p(3, 2), p(2, 2), p(2, 3), p(2, 4), p(1, 4), p(1, 3), p(1, 2), p(1, 1), p(2, 1)]).

