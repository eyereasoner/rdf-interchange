% ODRL policy rules, trust scores, and requested flows are RDF data. The rules
% produce one deterministic FPV-style decision report.
%% goal: result_rdf(_, _, _, _)

% These helpers are called with some arguments known. Tabling evaluates them
% on demand, also in engines that otherwise run rules forward.
:- table iri_term/2.
:- table rdf_link/3.
:- table rdf_number/3.
:- table policy_rule/6.

trust_flow_report([Care, Clinic, Ads]) :-
  flow_decision(flow_care, Care),
  flow_decision(flow_clinic, Clinic),
  flow_decision(flow_ads, Ads).

flow_decision(Flow, decision(Flow, permit, confidence(Score), status(executable_flow))) :-
  permitted_flow(Flow, Score).
flow_decision(Flow, decision(Flow, review, confidence(Score), risk(trustworthiness_risk))) :-
  review_flow(Flow, Score).
flow_decision(Flow, decision(Flow, deny, status(blocked_flow), risk(unwanted_disclosure))) :-
  prohibited_flow(Flow).

permitted_flow(Flow, Score) :-
  flow_request(Flow, Source, Recipient, Data, Action, Purpose),
  policy_rule(odrl(permission), Rule, Recipient, Data, Action, Purpose),
  rdf_number(Rule, ex(minTrust), Minimum),
  rdf_number(Source, ex(trustScore), Score),
  Score >= Minimum.

review_flow(Flow, Score) :-
  flow_request(Flow, Source, Recipient, Data, Action, Purpose),
  policy_rule(odrl(permission), Rule, Recipient, Data, Action, Purpose),
  rdf_number(Rule, ex(minTrust), Minimum),
  rdf_number(Source, ex(trustScore), Score),
  Score < Minimum.

prohibited_flow(Flow) :-
  flow_request(Flow, _Source, Recipient, Data, Action, Purpose),
  policy_rule(odrl(prohibition), _Rule, Recipient, Data, Action, Purpose).

flow_request(Flow, Source, Recipient, Data, Action, Purpose) :-
  flow_resource(Flow, Resource),
  rdf_link(Resource, ex(source), Source),
  rdf_link(Resource, ex(recipient), Recipient),
  rdf_link(Resource, ex(data), Data),
  rdf_link(Resource, ex(requestedAction), Action),
  rdf_link(Resource, ex(requestedPurpose), Purpose).

policy_rule(Type, Rule, Recipient, Data, Action, Purpose) :-
  rdf_link(ex('trust-policy'), Type, Rule),
  rdf_link(Rule, odrl(assignee), Recipient),
  rdf_link(Rule, odrl(target), Data),
  rdf_link(Rule, odrl(action), Action),
  rdf_link(Rule, odrl(purpose), Purpose).

flow_resource(flow_care, ex('flow-care')).
flow_resource(flow_clinic, ex('flow-clinic')).
flow_resource(flow_ads, ex('flow-ads')).

rdf_link(Subject, Predicate, Object) :-
  iri_term(Subject, SubjectIri),
  iri_term(Predicate, PredicateIri),
  rdf(iri(SubjectIri), iri(PredicateIri), iri(ObjectIri), default_graph),
  iri_term(Object, ObjectIri).

rdf_number(Subject, Predicate, Number) :-
  iri_term(Subject, SubjectIri),
  iri_term(Predicate, PredicateIri),
  rdf(iri(SubjectIri), iri(PredicateIri), literal(Text, datatype(_Datatype)), default_graph),
  atom_chars(Text, Chars),
  number_chars(Number, Chars).

iri_term(ex(Name), Iri) :- namespace_iri('https://example.org/', Name, Iri).
iri_term(odrl(Name), Iri) :- namespace_iri('http://www.w3.org/ns/odrl/2/', Name, Iri).

namespace_iri(Prefix, Name, Iri) :- atom_concat(Prefix, Name, Iri).

% RDF form of each flow decision.
result_rdf(iri(FlowIri), iri('https://example.org/decision'), iri(DecisionIri), default_graph) :-
  flow_decision(Flow, DecisionTerm),
  decision_name(DecisionTerm, Decision),
  flow_resource(Flow, FlowResource),
  iri_term(FlowResource, FlowIri),
  atom_concat('https://example.org/', Decision, DecisionIri).
result_rdf(iri(FlowIri), iri('https://example.org/confidence'), literal(Text, datatype('http://www.w3.org/2001/XMLSchema#decimal')), default_graph) :-
  flow_decision(Flow, DecisionTerm),
  decision_has_confidence(DecisionTerm),
  flow_resource(Flow, FlowResource),
  iri_term(FlowResource, FlowIri),
  flow_request(Flow, Source, _Recipient, _Data, _Action, _Purpose),
  iri_term(Source, SourceIri),
  rdf(iri(SourceIri), iri('https://example.org/trustScore'), literal(Text, datatype(_)), default_graph).
result_rdf(iri(FlowIri), iri('https://example.org/status'), iri(StatusIri), default_graph) :-
  flow_decision(Flow, DecisionTerm),
  decision_status(DecisionTerm, Status),
  flow_resource(Flow, FlowResource),
  iri_term(FlowResource, FlowIri),
  atom_concat('https://example.org/', Status, StatusIri).
result_rdf(iri(FlowIri), iri('https://example.org/risk'), iri(RiskIri), default_graph) :-
  flow_decision(Flow, DecisionTerm),
  decision_risk(DecisionTerm, Risk),
  flow_resource(Flow, FlowResource),
  iri_term(FlowResource, FlowIri),
  atom_concat('https://example.org/', Risk, RiskIri).

decision_name(decision(_, permit, _, _), permit).
decision_name(decision(_, review, _, _), review).
decision_name(decision(_, deny, _, _), deny).
decision_has_confidence(decision(_, permit, confidence(_), _)).
decision_has_confidence(decision(_, review, confidence(_), _)).
decision_status(decision(_, permit, _, status(Status)), Status).
decision_status(decision(_, deny, status(Status), _), Status).
decision_risk(decision(_, review, _, risk(Risk)), Risk).
decision_risk(decision(_, deny, _, risk(Risk)), Risk).

% ISO Prolog helper: print the complete test result as rdf/4 facts.
write_results :-
  result_rdf(S, P, O, G),
  write_term(rdf(S, P, O, G), [quoted(true)]),
  write('.'),
  nl,
  fail.
write_results.
