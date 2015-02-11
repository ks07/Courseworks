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

%% Dumb hard-coded solution
%% q5_corner_move :-
%% 	ailp_start_position(S),
%% 	ailp_show_move(S, p(1, 1)),
%% 	ailp_show_move(p(1, 1), p(1, 4)),
%% 	ailp_show_move(p(1, 4), p(4, 4)),
%% 	ailp_show_move(p(4, 4), p(4, 1)),
%% 	ailp_show_move(p(4, 1), p(1, 1)).

%% Dumb over-engineered solution
q5_corner_move :-
	ailp_start_position(S),
	term_to_atom([S],PathA),
	do_command([mower,console,PathA],_),
	q5_corner_move_step(S,[S]).

q5_corner_move_corners(p(1, 1)).
q5_corner_move_corners(p(1, 4)).
q5_corner_move_corners(p(4, 4)).
q5_corner_move_corners(p(4, 1)).

q5_corner_move_step(_, Path) :-
	length(Path, 5).
q5_corner_move_step(Pos, Path) :-
	q5_corner_move_corners(C),
	\+ memberchk(C, Path),
	ailp_show_move(Pos, C),
	term_to_atom([C|Path],PathA),
	do_command([mower,console,PathA],_),
	q5_corner_move_step(C, [C|Path]).

q5_corner_move2 :-
	ailp_start_position(S),
	term_to_atom([S],PathA),
	do_command([mower,console,PathA],_),
	q5_corner_move_step2(S,[S]).

q5_corner_move_corners2(p(X, Y)) :-
	ailp_grid_size(S),
	(Y = S; Y = 1),
	(X = S; X = 1).

q5_corner_move_step2(_, Path) :-
	length(Path, 5).
%% Alternatively:  findall(C, q5_corner_move_corners2(C), B), subset(B, path).

q5_corner_move_step2(Pos, Path) :-
	q5_corner_move_corners2(C),
	\+ memberchk(C, Path),
	ailp_show_move(Pos, C),
	term_to_atom([C|Path],PathA),
	do_command([mower,console,PathA],_),
	q5_corner_move_step2(C, [C|Path]).
	
