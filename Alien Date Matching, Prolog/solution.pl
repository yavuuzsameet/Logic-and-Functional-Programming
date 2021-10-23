% yavuz samet topcuoglu
% compiling: yes
% complete: yes

:- encoding(utf8).
:- ['load.pro']. %include knowledge base.

% 3.1 glanian_distance(Name1, Name2, Distance) 5 points
% finds the distance between two glanians.
glanian_distance(Name1, Name2, Distance):- 
    expects(Name1, _, Expectations),
    glanian(Name2, _, Features),
    %below lines calculate distance.
    list_subtraction(Expectations, Features, Subtraction),
    square(Subtraction, Sqr),
    sum_list(Sqr, Summationes),
    Distance is sqrt(Summationes).

% 3.2 weighted_glanian_distance(Name1, Name2, Distance) 10 points
% finds the weighted distance between two glanians.
weighted_glanian_distance(Name1, Name2, Distance):-
    expects(Name1, _, Expectations),
    weight(Name1, Weights),
    glanian(Name2, _,  Features),
    %below lines calculate weighted distance.
    list_subtraction(Expectations, Features, Subtraction),
    square(Subtraction, Sqr),
    multiply_two_lists(Sqr, Weights, Mult),
    sum_list(Mult, Summationes),
    Distance is sqrt(Summationes).

% 3.3 find_possible_cities(Name, CityList) 5 points
% finds the liked cities and current city of given glanian.
find_possible_cities(Name, CityList):-
    member(Name, ListC), city(Habitat, ListC, _),
    likes(Name, _, LikedCities),
    CityList = [Habitat | LikedCities], !.

% 3.4 merge_possible_cities(Name1, Name2, MergedCities) 5 points
% unites the possible cities of two glanians.
merge_possible_cities(Name1, Name2, MergedCities):-
    member(Name1, ListC1), city(Habitat1, ListC1, _),
    likes(Name1, _, LikedCities1),
    CityList1 = [Habitat1 | LikedCities1],
    list_to_ord_set(CityList1, Set1),
    member(Name2, ListC2), city(Habitat2, ListC2, _),
    likes(Name2, _, LikedCities2),
    CityList2 = [Habitat2 | LikedCities2],
    list_to_ord_set(CityList2, Set2),
    ord_union(Set1, Set2, MergedCities), !.

% 3.5 find_mutual_activities(Name1, Name2, MutualActivities) 5 points
% finds the intersection of the liked activities of two glanians.
find_mutual_activities(Name1, Name2, MutualActivities):-
    likes(Name1, Activities1, _),
    list_to_ord_set(Activities1, Set1),
    likes(Name2, Activities2, _),
    list_to_ord_set(Activities2, Set2),
    ord_intersection(Set1, Set2, MutualActivities).

% 3.6 find_possible_targets(Name, Distances, TargetList) 10 points
% finds all glanians with gender which is member of set of expected genders of given glanian and sorts them according to distance.
find_possible_targets(Name, Distances, TargetList):-
    expects(Name, ExpectedGenders, _),
    % find all pairs
    findall(Distance-Target, (member(Gender, ExpectedGenders), glanian(Target, Gender, _), not(Name = Target), glanian_distance(Name, Target, Distance)), List),
    list_to_ord_set(List, Set),
    divide_dashed_list(Set, Distances, TargetList).

% 3.7 find_weighted_targets(Name, Distances, TargetList) 15 points
% finds all glanians with gender which is member of set of expected genders of given glanian and sorts them according to weighted distance.
find_weighted_targets(Name, Distances, TargetList):-
    expects(Name, ExpectedGenders, _),
    % find all pairs
    findall(Distance-Target, (member(Gender, ExpectedGenders), glanian(Target, Gender, _), not(Name = Target), weighted_glanian_distance(Name, Target, Distance)), List),
    list_to_ord_set(List, Set),
    divide_dashed_list(Set, Distances, TargetList).

% 3.8 find_my_best_target(Name, Distances, Activities, Cities, Targets) 20 points
% finds the best targets of given glanian in terms of mutual activities, possible cities and plausible genders.
% target means that we are only interested in Name's requests.
find_my_best_target(Name, Distances, Activities, Cities, Targets):-

    expects(Name, ExpectedGenders, _),
    dislikes(Name, DislikedActivities, DislikedCities, LimitList),
    likes(Name, LikedActivities, LikedCities),

    % find all quadruplets
    findall(Distance-Activity-City-Target, (

        target_qualifications(Target, Name, ExpectedGenders, LimitList, DislikedActivities),
        city_qualifications(City, Name, LikedCities, LikedActivities, DislikedCities, Target, Activity, DislikedActivities),
        distances(Distance, Name, Target)

    ), Quadruple),
    
    sort(Quadruple, Sorted),
    divide_dashed_list(Sorted, Temp1, Targets), divide_dashed_list(Temp1, Temp2, Cities), divide_dashed_list(Temp2, Distances, Activities), !.

% 3.9 find_my_best_match(Name, Distances, Activities, Cities, Targets) 25 points
% finds the best matches of given glanian in terms of mutual activities, possible cities and plausible genders.
% match means that we are both interested in Name's and Target's requests.
find_my_best_match(Name, Distances, Activities, Cities, Targets):-

    expects(Name, ExpectedGenders, _),
    dislikes(Name, DislikedActivities, DislikedCities, LimitList),
    likes(Name, LikedActivities, LikedCities),

    % find all quadruplets
    findall(Distance-Activity-City-Target, (

        target_matcher(Target, Name, ExpectedGenders, LimitList, DislikedActivities),
        city_matcher(City, Name, LikedCities, LikedActivities, DislikedCities, Target, Activity, DislikedActivities),
        distances_matcher(Distance, Name, Target)

    ), Quadruple),

    sort(Quadruple, Sorted),
    divide_dashed_list(Sorted, Temp1, Targets), divide_dashed_list(Temp1, Temp2, Cities), divide_dashed_list(Temp2, Distances, Activities), !.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% returns true if Name and Target had a relation.
prev(Name, Target):-
    old_relation([Name, Target]) ; old_relation([Target, Name]).

/*
 finds targets of given glanian in terms of:
 -expected genders
 -not having previous relationship.
 -in bounds of tolerance limit.
 -not having obvious difference in interests of activities.
*/
target_qualifications(Target, Name, ExpectedGenders, LimitList, DislikedActivities):-
    (member(Gender, ExpectedGenders), glanian(Target, Gender, Features)),
    (not(prev(Name, Target))),
    (feature_limit_calculator(LimitList, Features)),
    (conflict_checker(DislikedActivities, Target)).

/*
 finds cities which are:
 -in possible cities or includes a liked activity of given glanian.
 -member of merged city list of given glanian and its target.
 -not a disliked city of given glanian.

 finds activities which:
 -can be done in the given city.
 -are not a disliked activity of a given glanian. 
*/
city_qualifications(City, Name, LikedCities, LikedActivities, DislikedCities, Target, Activity, DislikedActivities):-
    (member(City, LikedCities) ; (city(City, Habitants, _), member(Name, Habitants)) ; (city(City, _, ActivityList), member(Activity, ActivityList), member(Activity, LikedActivities))),
    (merge_possible_cities(Name, Target, CityList), member(City, CityList)),
    (city(City, _, ActivityList), member(Activity, ActivityList)),
    (not(member(Activity, DislikedActivities))),
    (not(member(City, DislikedCities))).

% finds weighted distances between two glanians.
distances(Distance, Name, Target):-
    weighted_glanian_distance(Name, Target, Distance).


% finds matching targets using target_qualifications twice, one for Name and one for Target.
target_matcher(Target, Name, ExpectedGenders, LimitList, DislikedActivities):-
    target_qualifications(Target, Name, ExpectedGenders, LimitList, DislikedActivities),

    expects(Target, ExpectedGendersOfTarget, _),
    dislikes(Target, DislikedActivitiesOfTarget, _, LimitListOfTarget),

    target_qualifications(Name, Target, ExpectedGendersOfTarget, LimitListOfTarget, DislikedActivitiesOfTarget).

% finds matching cities using city_qualifications twice, one for Name and one for Target.
city_matcher(City, Name, LikedCities, LikedActivities, DislikedCities, Target, Activity, DislikedActivites):-
    city_qualifications(City, Name, LikedCities, LikedActivities, DislikedCities, Target, Activity, DislikedActivites),
    
    likes(Target, LikedActivitiesOfTarget, LikedCitiesOfTarget),
    dislikes(Target, DislikedActivitiesOfTarget, DislikedCitiesOfTarget, _),
    
    city_qualifications(City, Target, LikedCitiesOfTarget, LikedActivitiesOfTarget, DislikedCitiesOfTarget, Name, Activity, DislikedActivitiesOfTarget).

% finds weighted matching distance between two glanians.
distances_matcher(Distance, Name, Target):-
    weighted_glanian_distance(Name, Target, D1),
    weighted_glanian_distance(Target, Name, D2),
    Distance is ((D1+D2)/2).

/*
 checks whether the features of Target is in the bounds of tolerance limit.
 L: LimitList. (do not forget that it is a list of list)
 F: Features.

 H: Head of ...
 T: Tail of ...

 returns true, if LimitList does not contain any boundary for a feature.
               features are in the boundary of tolerances. 
*/
feature_limit_calculator([], []).
feature_limit_calculator([[]], []).
feature_limit_calculator([HL|TL], [HF|TF]):-
    (HL = [] ; (HL = [HHL|THL], THL = [X], (HHL < HF), (X > HF))),
    feature_limit_calculator(TL,TF), !.

/*
 checks whether given glanian and its target has an excessive number of unwanted overlaps.
 overlapping number of activities can be at most 2.
*/
conflict_checker(DislikedActivities, Target):-
    likes(Target, LikedActivities, _),
    list_to_ord_set(DislikedActivities, DislikedSet),
    list_to_ord_set(LikedActivities, LikedSet),
    ord_intersection(DislikedSet, LikedSet, Middle),
    length_of(Middle, Length),
    Length < 3, !.

%
% The predicates used below are copied or inspired from the PS, Alper Ahmetoglu.
%
list_subtraction([],[],[]).
list_subtraction([H1|T1], [H2|T2], [Head|Tail]):-
    list_subtraction(T1, T2, Tail),
    ((H1 = -1, Head is 0, !);(Head is H1-H2)).

length_of([], 0).
length_of(List, Length) :-
    [_|Tail] = List,
    length_of(Tail, TailLength),
    Length is TailLength+1.

square([], []).
square([Head|Tail], Result) :-
    square(Tail, TailResult),
    HeadResult is Head*Head,
    Result = [HeadResult|TailResult].

multiply_two_lists([], [], []).
multiply_two_lists([H1|T1], [H2|T2], [Head|Tail]) :-
    multiply_two_lists(T1, T2, Tail),
    Head is H1*H2.

divide_dashed_list([], [], []).
divide_dashed_list([Head|Tail], [HeadFirst|TailFirst], [HeadSecond|TailSecond]) :-
    HeadFirst-HeadSecond = Head,
    divide_dashed_list(Tail, TailFirst, TailSecond).