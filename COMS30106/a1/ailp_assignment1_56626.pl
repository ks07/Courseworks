candidate_number(56626).

q1(assignment1_module:start_position_personal(P)).

q2a(new_pos(p(1,1),e,P)).

q2b(19).

q3([s,e,w,n]).

%% First deadend found is in fact the final cell
q4a([p(3, 3), p(3, 4), p(4, 4), p(4, 3), p(4, 2), p(3, 2), p(2, 2), p(2, 3), p(2, 4), p(1, 4), p(1, 3), p(1, 2), p(1, 1), p(2, 1), p(3, 1), p(4, 1)]).

%% Second deadend found is at (2,4) after backtracking to (2,3) -> (1,3)
q4b([p(3, 3), p(3, 4), p(4, 4), p(4, 3), p(4, 2), p(3, 2), p(2, 2), p(2, 3), p(2, 4), p(1, 4), p(1, 3), p(1, 2), p(1, 4), p(2, 4)]).

%% First path == First deadend path
q4c([p(3, 3), p(3, 4), p(4, 4), p(4, 3), p(4, 2), p(3, 2), p(2, 2), p(2, 3), p(2, 4), p(1, 4), p(1, 3), p(1, 2), p(1, 1), p(2, 1), p(3, 1), p(4, 1)]).

%% Second path has a lot of backtracking
q4d([p(3, 3), p(3, 4), p(4, 4), p(4, 3), p(4, 2), p(4, 1), p(3, 1), p(3, 2), p(2, 2), p(2, 3), p(2, 4), p(1, 4), p(1, 3), p(1, 2), p(1, 1), p(2, 1)]).

%% q5_corner_move :-
%% 	ailp_show_move(p(0, 0), p(0, 4)),
%% 	ailp_show_move(p(0, 4), p(4, 4)),
%% 	ailp_show_move(p(4, 4), p(4, 0)),
%% 	ailp_show_move(p(4, 0), p(0, 0)).

q5_corner_move :-
	q5_corner_move_corners(C),
	q5_corner_move_step([C]).

q5_corner_move_corners(p(0, 0)).
q5_corner_move_corners(p(0, 4)).
q5_corner_move_corners(p(4, 4)).
q5_corner_move_corners(p(4, 0)).

q5_corner_move_step(Path) :-
	length(Path, 4).
q5_corner_move_step(Path) :-
	q5_corner_move_corners(C),
	\+ memberchk(C, Path),
	Path = [P1|_],
	write(P1), nl,
	ailp_show_move(P1, C),
	q5_corner_move_step([C|Path]).
