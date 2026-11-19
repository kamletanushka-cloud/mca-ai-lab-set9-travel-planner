domains
    city = symbol
    city_list = city*

predicates
    city_info(integer, city, string)
    edge(city, city, integer, integer, integer)
    member(city, city_list)
    reverse_list(city_list, city_list, city_list)
    print_route(city_list)
    find_path(city, city, city, city_list, city_list, integer, integer, integer)
    show_all_routes(city, city, city)
    best_route(integer, city, city, city, city_list, integer, integer, integer)
    update_best(integer, city_list, integer, integer, integer)
    is_better(integer, integer, integer, integer, integer, integer, integer)
    resolve_avoid(integer, city)
    explain_choice(integer)
    run_planner

database
    best_found(city_list, integer, integer, integer)
    route_count(integer)

clauses
    /* City lookup: ID, internal symbol, display label */
    city_info(1, city_a, "City A").
    city_info(2, city_b, "City B").
    city_info(3, city_c, "City C").
    city_info(4, city_d, "City D").
    city_info(5, city_e, "City E").
    city_info(6, city_f, "City F").

    /* Directed connections: edge(From, To, Cost_Rs, Time_Hrs, Distance_Km) */
    edge(city_a, city_b, 250, 2, 100).
    edge(city_b, city_f, 600, 4, 250).
    edge(city_a, city_c, 400, 2, 120).
    edge(city_c, city_f, 700, 3, 200).
    edge(city_b, city_d, 300, 3, 150).
    edge(city_c, city_d, 200, 2, 100).
    edge(city_d, city_e, 350, 3, 180).
    edge(city_e, city_f, 250, 2, 120).

    /* Standard list membership check for Turbo Prolog 2.0 */
    member(X, [X|_]).
    member(X, [_|T]) :-
        member(X, T).

    /* Reverse accumulated visited list into forward order */
    reverse_list([], Acc, Acc).
    reverse_list([H|T], Acc, Rev) :-
        reverse_list(T, [H|Acc], Rev).

    /* Print route nicely using display names */
    print_route([]).
    print_route([Last]) :-
        city_info(_, Last, Name),
        write(Name), !.
    print_route([H|T]) :-
        city_info(_, H, Name),
        write(Name), write(" -> "),
        print_route(T).

    /* Resolve avoided city without semicolon disjunction */
    resolve_avoid(0, none) :- !.
    resolve_avoid(AvoidNum, Avoid) :-
        city_info(AvoidNum, Avoid, _).

    /* Recursive DFS path finder with city avoidance & dynamic summation */
    find_path(Dest, Dest, _, Visited, Path, 0, 0, 0) :-
        reverse_list(Visited, [], Path).

    find_path(Curr, Dest, Avoid, Visited, Path, TotalCost, TotalTime, TotalDist) :-
        edge(Curr, Next, C, T, D),
        Next <> Avoid,
        not(member(Next, Visited)),
        find_path(Next, Dest, Avoid, [Next|Visited], Path, SubCost, SubTime, SubDist),
        TotalCost = C + SubCost,
        TotalTime = T + SubTime,
        TotalDist = D + SubDist.

    /* Display all available routes between Source and Dest */
    show_all_routes(Src, Dest, Avoid) :-
        retractall(route_count(_)),
        assertz(route_count(0)),
        find_path(Src, Dest, Avoid, [Src], Path, Cost, Time, Dist),
        retract(route_count(N)),
        N1 = N + 1,
        assertz(route_count(N1)),
        write("  Route "), write(N1), write(": "),
        print_route(Path), nl,
        write("           Cost: Rs. "), write(Cost),
        write(" | Time: "), write(Time), write(" hrs"),
        write(" | Distance: "), write(Dist), write(" km"), nl,
        fail.
    show_all_routes(_, _, _) :-
        route_count(0),
        write("  No available routes found between selected cities."), nl, !.
    show_all_routes(_, _, _).

    /* Comparison helper: Choice 1=Cheapest, 2=Fastest, 3=Shortest */
    is_better(1, C1, _, _, C2, _, _) :- C1 < C2.
    is_better(2, _, T1, _, _, T2, _) :- T1 < T2.
    is_better(3, _, _, D1, _, _, D2) :- D1 < D2.

    /* Update best route stored in internal database */
    update_best(_, Path, Cost, Time, Dist) :-
        not(best_found(_, _, _, _)),
        assertz(best_found(Path, Cost, Time, Dist)), !.
    update_best(Choice, Path, Cost, Time, Dist) :-
        best_found(_, BestC, BestT, BestD),
        is_better(Choice, Cost, Time, Dist, BestC, BestT, BestD),
        retractall(best_found(_, _, _, _)),
        assertz(best_found(Path, Cost, Time, Dist)), !.
    update_best(_, _, _, _, _).

    /* Search all paths and keep the optimal one for Choice */
    best_route(Choice, Src, Dest, Avoid, _, _, _, _) :-
        retractall(best_found(_, _, _, _)),
        find_path(Src, Dest, Avoid, [Src], Path, Cost, Time, Dist),
        update_best(Choice, Path, Cost, Time, Dist),
        fail.
    best_route(_, _, _, _, BestPath, BestCost, BestTime, BestDist) :-
        best_found(BestPath, BestCost, BestTime, BestDist).

    /* Reason explanation */
    explain_choice(1) :-
        write("Reason: Selected because it has the lowest total travel cost.").
    explain_choice(2) :-
        write("Reason: Selected because it requires the minimum travel time.").
    explain_choice(3) :-
        write("Reason: Selected because it covers the shortest total distance.").

    /* Main interactive planner */
    run_planner :-
        write("=========================================="), nl,
        write("       INTELLIGENT TRAVEL PLANNER"), nl,
        write("=========================================="), nl,
        write("AVAILABLE CITIES:"), nl,
        write("  1. City A    2. City B    3. City C"), nl,
        write("  4. City D    5. City E    6. City F"), nl,
        write("------------------------------------------"), nl,
        write("Enter source city number (1-6): "),
        readint(SrcNum),
        write("Enter destination city number (1-6): "),
        readint(DestNum),
        write("Enter city number to avoid (0 for none): "),
        readint(AvoidNum),
        write("Travel Preference: 1.Cheapest  2.Fastest  3.Shortest"), nl,
        write("Enter preference (1-3): "),
        readint(Choice),

        city_info(SrcNum, Src, SrcName),
        city_info(DestNum, Dest, DestName),
        Src <> Dest,
        Choice >= 1, Choice <= 3,

        resolve_avoid(AvoidNum, Avoid),
        Avoid <> Src,
        Avoid <> Dest,

        nl,
        write("========== ALL POSSIBLE ROUTES ==========="), nl,
        show_all_routes(Src, Dest, Avoid),

        nl,
        write("========= SELECTED OPTIMAL ROUTE ========="), nl,
        write("Source      : "), write(SrcName), nl,
        write("Destination : "), write(DestName), nl,
        best_route(Choice, Src, Dest, Avoid, OptPath, OptCost, OptTime, OptDist),
        write("Best Route  : "), print_route(OptPath), nl,
        write("Total Cost  : Rs. "), write(OptCost), nl,
        write("Total Time  : "), write(OptTime), write(" hours"), nl,
        write("Distance    : "), write(OptDist), write(" km"), nl,
        explain_choice(Choice), nl,

        nl,
        write("====== CHEAPEST VS FASTEST SUMMARY ======="), nl,
        best_route(1, Src, Dest, Avoid, CheapPath, CheapC, CheapT, CheapD),
        write("Cheapest : "), print_route(CheapPath),
        write(" (Rs."), write(CheapC), write(", "), write(CheapT),
        write("h, "), write(CheapD), write("km)"), nl,
        best_route(2, Src, Dest, Avoid, FastPath, FastC, FastT, FastD),
        write("Fastest  : "), print_route(FastPath),
        write(" (Rs."), write(FastC), write(", "), write(FastT),
        write("h, "), write(FastD), write("km)"), nl,
        write("=========================================="), nl, !.

    run_planner :-
        nl,
        write("=========================================="), nl,
        write("No valid route available for your selection"), nl,
        write("(Invalid city/preference, or path blocked)."), nl,
        write("=========================================="), nl.

goal
    run_planner.