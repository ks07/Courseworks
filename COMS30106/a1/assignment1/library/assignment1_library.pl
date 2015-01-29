/*
 *      assignment1_module.pro
 *
 *		assignment-specific program NOT to be edited by students.
 */


:- module(assignment1_module,
	  [ ailp_show_move/2,		% +Old_pos, +New_pos 
	    ailp_start_position/1,	% binds with starting position p(X,Y)
	    ailp_show_complete/0,
	    ailp_grid_size/1,		% -Size
	    reset/0
	  ]).

:- set_homepage('mower.html').

% Commands:
% 	[AgentId, say, Atom]
% 	[AgentId, console, Atom]
% 	[AgentId, go, Dir]
% 	[AgentId, move, X,Y]
% 	[AgentId, colour, X,Y,Colour]
% 	[god, reset, Initial_state]		// asserted by reset/0 to initialise game world in web page

ailp_show_move(p(X0,Y0),p(X1,Y1)) :-
	do_command([mower, colour, X0, Y0, lighter]),
	do_command([mower, colour, X1, Y1, lighter]),
	do_command([mower, move, X1, Y1], _Result).
	%% term_to_atom(Result, A), do_command([mower, console, A]).
	%	could succeed or fail here depending on legality of attempted move (indciated by 'fail= @true' in R)

ailp_show_complete :-
	do_command([mower, say, 'Finished!'], _R).

ailp_grid_size(4).
%ailp_start_position(1,1).

% can change to use either start_position/1 or start_position_personal/1
ailp_start_position(P)  :- start_position_personal(P).

%% ailp_start_position(p(N,N)) :-
%% 	N = 1.
start_position(p(1,1)).

% X position is mod(candidatenumber/gridwidth)
% Y position is mod(second digit/gridwidth)
start_position_personal(p(X,Y)):-
	candidate_number(Z),
	ailp_grid_size(N),
	X is mod(Z,N) + 1,
	number_codes(Z,[A|[Y1|B]]),
	Y2 is Y1 - 48,
	Y is mod(Y2,N) + 1.
	
	

reset :-
	ailp_grid_size(N),
	ailp_start_position(p(X,Y)),
	reset([
		grid_size=N,
		cells=[
			[forestgreen, 1,1, N,N]
		],
		agents=[
			[mower, 6, royalblue, X,Y]
		]
	]),
	do_command([mower, colour, X,Y, lighter]).

