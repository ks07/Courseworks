candidate_number(56626).

%% Get the start position.
q1(ailp_start_position(P)).

%% Calculate new position moving East from 1,1
q2a(new_pos(p(1,1),e,P)).

%% Failing line for moving North from 1,1
q2b(19).

%% Order/priority of directions.
q3([s,e,w,n]).

%% First deadend found is in fact the final cell
q4a([p(3, 3), p(3, 4), p(4, 4), p(4, 3), p(4, 2), p(3, 2), p(2, 2), p(2, 3), p(2, 4), p(1, 4), p(1, 3), p(1, 2), p(1, 1), p(2, 1), p(3, 1), p(4, 1)]).

%% Second deadend found is at (2,4) after backtracking to (2,3) -> (1,3)
q4b([p(3, 3), p(3, 4), p(4, 4), p(4, 3), p(4, 2), p(3, 2), p(2, 2), p(2, 3), p(2, 4), p(1, 4), p(1, 3), p(1, 2), p(1, 4), p(2, 4)]).

%% First path == First deadend path
q4c([p(3, 3), p(3, 4), p(4, 4), p(4, 3), p(4, 2), p(3, 2), p(2, 2), p(2, 3), p(2, 4), p(1, 4), p(1, 3), p(1, 2), p(1, 1), p(2, 1), p(3, 1), p(4, 1)]).

%% Second path has a lot of backtracking
q4d([p(3, 3), p(3, 4), p(4, 4), p(4, 3), p(4, 2), p(4, 1), p(3, 1), p(3, 2), p(2, 2), p(2, 3), p(2, 4), p(1, 4), p(1, 3), p(1, 2), p(1, 1), p(2, 1)]).

%% Move to all 4 corners on fixed 4x4 grid.
q5_corner_move :-
	%% Force a reset at the very beginning so we look nicer.
	reset,
	%% Grab our start position
	ailp_start_position(S),
	%% Start recursive calls
	q5_corner_move_step(S,[]).

%% Define all 4 fixed corners.
q5_corner_move_corners(p(1, 1)).
q5_corner_move_corners(p(1, 4)).
q5_corner_move_corners(p(4, 4)).
q5_corner_move_corners(p(4, 1)).

%% Base case for recursion.
q5_corner_move_step(_, Path) :-
	length(Path, 4).

%% Recursive step.
q5_corner_move_step(Pos, Path) :-
	%% Find a corner to visit
	q5_corner_move_corners(C),
	%% Check we haven't already visited this corner
	\+ memberchk(C, Path),
	%% Visualise movement from current pos to new corner
	ailp_show_move(Pos, C),
	term_to_atom([C|Path],PathA),
	do_command([mower,console,PathA],_),
	%% Recurse
	q5_corner_move_step(C, [C|Path]).

%% Move to all 4 corners on any sized grid.
q5_corner_move2 :-
	%% Force a reset at the very beginning so we look nicer.
	reset,
	%% Get our start position
	ailp_start_position(S),
	%% Call recursive predicate
	q5_corner_move_step2(S,[]).

%% Get a corner.
q5_corner_move_corners2(p(X, Y)) :-
	ailp_grid_size(S),
	(Y = S; Y = 1),
	(X = S; X = 1).

%% Base case for recursion.
q5_corner_move_step2(_, Path) :-
	length(Path, 4).
%% Alternatively could check the path holds all 4 corners: findall(C, q5_corner_move_corners2(C), B), subset(B, path).

%% Recursive call to move between corners.
q5_corner_move_step2(Pos, Path) :-
	%% Get a corner.
	q5_corner_move_corners2(C),
	%% Check it is unvisited
	\+ memberchk(C, Path),
	%% Visualise move from current pos to corner
	ailp_show_move(Pos, C),
	term_to_atom([C|Path],PathA),
	do_command([mower,console,PathA],_),
	%% Recurse
	q5_corner_move_step2(C, [C|Path]).

%% Spiral around the board starting from a corner.
q6_spiral(Path) :-
	%% Select a start corner/rotation pair
	q5_corner_move_corners(Pos),
	q6_rot(Rot),
	%% Find a suitable start direction.
	q6_start_direction(Rot, Pos, Dir),
	%% Force a reset so that once done backtracking the new spiral is clear. (Optional!)
	reset,
	%% Visualise from start position.
	ailp_start_position(S),
	ailp_show_move(S,Pos),
	%% Step into recursive algo
	q6_spiral_step(Rot, Dir, Pos, [Pos], PathR),
	%% Reverse the path into the right order.
	reverse(PathR, Path).

%% Define the two possible rotations (counter-)clockwise
q6_rot(c).
q6_rot(cc).

%% Pick a starting direction based on our location.

%% We are on the north edge (x,1) going clockwise
q6_start_direction(c, p(_, 1), e).
%% On south edge going clockwise
q6_start_direction(c, p(_, Y), w) :-
	ailp_grid_size(Y).
%% On north edge going counterclockwise
q6_start_direction(cc, p(_, 1), w).
%% On south edge going counterclockwise
q6_start_direction(cc, p(_, Y), e) :-
	ailp_grid_size(Y).

%% Suggest a direction. Either continue or turn clockwise (in that order).
q6_facing_try_direction(c, Facing, Try) :-
	Try = Facing;
	q6_clockwise(Facing, Try).

q6_facing_try_direction(cc, Facing, Try) :-
	Try = Facing;
	q6_counter_clockwise(Facing, Try).

%% Define clockwise turns.
q6_clockwise(n, e).
q6_clockwise(e, s).
q6_clockwise(s, w).
q6_clockwise(w, n).

%% Define counter-clockwise turns.
q6_counter_clockwise(Facing, NFacing) :-
	%% PROTIP: Counter-clockwise is the opposite!
	q6_clockwise(NFacing, Facing).

%% Given a rotation, direction of travel, position and path travelled search for a destination.
q6_spiral_step(_, _, _, R, R) :-
	%% Stop when we have visited every square. TODO: Call complete instead.
	L is 4*4,
	length(R,L).
q6_spiral_step(Rot, Facing, Pos, Path, R) :-
	%% Select a direction based on our direction.
	q6_facing_try_direction(Rot, Facing, NFacing),
	%% Use new_pos to calculate the destination location given the direction (if poss).
	new_pos(Pos,NFacing,Dest),
	%% Dest should not be in path
	\+ memberchk(Dest, Path),
	%% Visualise
	ailp_show_move(Pos, Dest),
	term_to_atom([Dest|Path],PathA),
	do_command([mower,console,PathA],_),
	%% Recurse to next move
	q6_spiral_step(Rot, NFacing, Dest, [Dest|Path], R).
