/*
 *      assignment1.pl
 *
 */


complete(L) :- 
	ailp_grid_size(N),
	N2 is N * N,
	length(L,N2),
	ailp_show_complete.

new_pos(p(X,Y), M, p(X1,Y1)) :-
	( M = s -> X1 =  X,    Y1 is Y+1
	; M = n -> X1 =  X,    Y1 is Y-1
	; M = e -> X1 is X+1,  Y1 =  Y
	; M = w -> X1 is X-1,  Y1 =  Y
	),
	X1 >= 1, Y1 >=1,
	ailp_grid_size(N),
	X1 =< N, Y1 =< N. 

m(s).
m(e).
m(w).
m(n).

candidate_number(56626).

next(L) :-
 	ailp_start_position(p(X,Y)),
 	next(p(X,Y),L).


%% P: current position, L: path taken by agent
next(P,L) :- 
	next(P,[P],Ps),
	reverse(Ps,L).

next(_,Ps,Ps) :- complete(Ps).
next(P,Ps,R) :-
	m(M),
	new_pos(P,M,P1),
	\+ memberchk(P1,Ps),
	ailp_show_move(P,P1),
	term_to_atom([P1|Ps],PsA),
	do_command([mower,console,PsA],_R),
	next(P1,[P1|Ps],R).

