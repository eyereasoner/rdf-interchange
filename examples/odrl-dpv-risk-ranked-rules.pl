% ODRL agreement rules and DPV-style needs are RDF data. The rules derive one
% risk per conflict, score it, and return one deterministic ranking.
%% goal: result_rdf(_, _, _, _)

% These helpers are called with some arguments known. Tabling evaluates them
% on demand, also in engines that otherwise run rules forward.
:- table iri_term/2.
:- table rdf_link/3.
:- table rdf_text/3.
:- table rdf_number/3.
:- table constraint_text/3.
:- table constraint_number/3.
:- table duty_action/2.
:- table notice_days/1.
:- table risk_triggered/3.

risk_report(Risk, Score, Level, Clause, Mitigation) :-
  risk_profile(_Profile, Risk, Rule, Need, Base, Mitigation),
  risk_triggered(Risk, Rule, Need),
  rdf_text(Rule, ex(clause), ClauseText),
  Clause = ClauseText,
  rdf_number(Need, ex(importance), Importance),
  Score is min(Base + Importance, 100),
  risk_level(Score, Level).

risk_profile(Profile, Risk, Rule, Need, Base, Mitigation) :-
  rdf_link(ex('consumer-policy'), ex(riskProfile), Profile),
  rdf_link(Profile, ex(risk), RiskResource),
  risk_resource(Risk, RiskResource),
  rdf_link(Profile, ex(policyRule), Rule),
  rdf_link(Profile, ex(need), Need),
  rdf_number(Profile, ex(baseScore), Base),
  rdf_link(Profile, ex(mitigation), MitigationResource),
  mitigation_resource(Mitigation, MitigationResource).

risk_triggered(deletion_risk, Rule, _Need) :-
  rdf_link(ex('consumer-policy'), odrl(permission), Rule),
  rdf_link(Rule, odrl(action), ex('remove-account')),
  \+ duty_action(Rule, ex(inform)),
  \+ notice_days(Rule).

risk_triggered(terms_risk, Rule, Need) :-
  rdf_link(ex('consumer-policy'), odrl(permission), Rule),
  rdf_link(Rule, odrl(action), ex('change-terms-action')),
  duty_action(Rule, ex(inform)),
  constraint_number(Rule, ex(noticeDays), Days),
  rdf_number(Need, ex(minimumNoticeDays), Minimum),
  Days < Minimum.

risk_triggered(sharing_risk, Rule, _Need) :-
  rdf_link(ex('consumer-policy'), odrl(permission), Rule),
  rdf_link(Rule, odrl(action), ex(disclose)),
  \+ constraint_text(Rule, ex(explicitConsent), 'true').

risk_triggered(portability_risk, Rule, _Need) :-
  rdf_link(ex('consumer-policy'), odrl(prohibition), Rule),
  rdf_link(Rule, odrl(action), ex(export)).

notice_days(Rule) :-
  constraint_number(Rule, ex(noticeDays), _Days).

duty_action(Rule, Action) :-
  rdf_link(Rule, odrl(duty), Duty),
  rdf_link(Duty, odrl(action), Action).

constraint_text(Rule, LeftOperand, Value) :-
  rdf_link(Rule, odrl(constraint), Constraint),
  rdf_link(Constraint, odrl('leftOperand'), LeftOperand),
  rdf_link(Constraint, odrl(operator), odrl(eq)),
  rdf_text(Constraint, odrl('rightOperand'), Value).

constraint_number(Rule, LeftOperand, Number) :-
  constraint_text(Rule, LeftOperand, Text),
  atom_chars(Text, Chars),
  number_chars(Number, Chars).

risk_level(Score, high) :- Score > 79.
risk_level(Score, moderate) :- Score > 49, Score < 80.

risk_resource(deletion_risk, ex('deletion-risk')).
risk_resource(terms_risk, ex('terms-risk')).
risk_resource(sharing_risk, ex('sharing-risk')).
risk_resource(portability_risk, ex('portability-risk')).

mitigation_resource(require_notice_before_deletion, ex('require-notice-before-deletion')).
mitigation_resource(require_14_days_notice, ex('require-14-days-notice')).
mitigation_resource(require_explicit_consent, ex('require-explicit-consent')).
mitigation_resource(permit_data_export, ex('permit-data-export')).

rdf_link(Subject, Predicate, Object) :-
  iri_term(Subject, SubjectIri),
  iri_term(Predicate, PredicateIri),
  rdf(iri(SubjectIri), iri(PredicateIri), iri(ObjectIri), default_graph),
  iri_term(Object, ObjectIri).

rdf_text(Subject, Predicate, Text) :-
  iri_term(Subject, SubjectIri),
  iri_term(Predicate, PredicateIri),
  rdf(iri(SubjectIri), iri(PredicateIri), literal(Text, datatype(_Datatype)), default_graph).

rdf_number(Subject, Predicate, Number) :-
  rdf_text(Subject, Predicate, Text),
  atom_chars(Text, Chars),
  number_chars(Number, Chars).

iri_term(ex(Name), Iri) :- namespace_iri('https://example.org/', Name, Iri).
iri_term(odrl(Name), Iri) :- namespace_iri('http://www.w3.org/ns/odrl/2/', Name, Iri).

namespace_iri(Prefix, Name, Iri) :- atom_concat(Prefix, Name, Iri).

% RDF form of the ranked consumer risks.
result_rdf(iri(RiskIri), iri('https://example.org/rank'), literal(RankText, datatype('http://www.w3.org/2001/XMLSchema#integer')), default_graph) :-
  consumer_ranked_item(Rank, Risk, _Score, _Level, _Clause, _Mitigation),
  risk_resource(Risk, RiskTerm), iri_term(RiskTerm, RiskIri), number_atom(Rank, RankText).
result_rdf(iri(RiskIri), iri('https://example.org/score'), literal(ScoreText, datatype('http://www.w3.org/2001/XMLSchema#integer')), default_graph) :-
  consumer_ranked_item(_Rank, Risk, Score, _Level, _Clause, _Mitigation),
  risk_resource(Risk, RiskTerm), iri_term(RiskTerm, RiskIri), number_atom(Score, ScoreText).
result_rdf(iri(RiskIri), iri('https://example.org/level'), iri(LevelIri), default_graph) :-
  consumer_ranked_item(_Rank, Risk, _Score, Level, _Clause, _Mitigation),
  risk_resource(Risk, RiskTerm), iri_term(RiskTerm, RiskIri), atom_concat('https://example.org/', Level, LevelIri).
result_rdf(iri(RiskIri), iri('https://example.org/clause'), literal(Clause, datatype('http://www.w3.org/2001/XMLSchema#string')), default_graph) :-
  consumer_ranked_item(_Rank, Risk, _Score, _Level, Clause, _Mitigation),
  risk_resource(Risk, RiskTerm), iri_term(RiskTerm, RiskIri).
result_rdf(iri(RiskIri), iri('https://example.org/mitigation'), iri(MitigationIri), default_graph) :-
  consumer_ranked_item(_Rank, Risk, _Score, _Level, _Clause, Mitigation),
  risk_resource(Risk, RiskTerm), iri_term(RiskTerm, RiskIri),
  mitigation_resource(Mitigation, MitigationTerm), iri_term(MitigationTerm, MitigationIri).

% A risk's rank is one more than the number of risks ahead of it: a higher
% score, or the same score and an earlier clause.
consumer_ranked_item(Rank, Risk, Score, Level, Clause, Mitigation) :-
  risk_report(Risk, Score, Level, Clause, Mitigation),
  aggregate_all(count, ranked_ahead(Score, Clause, _Other), Ahead),
  Rank is Ahead + 1.
ranked_ahead(Score, _Clause, Other) :-
  risk_report(Other, OtherScore, _OtherLevel, _OtherClause, _OtherMitigation),
  OtherScore > Score.
ranked_ahead(Score, Clause, Other) :-
  risk_report(Other, Score, _OtherLevel, OtherClause, _OtherMitigation),
  OtherClause @< Clause.
number_atom(Number, Atom) :- number_chars(Number, Chars), atom_chars(Atom, Chars).

% ISO Prolog helper: print the complete test result as rdf/4 facts.
write_results :-
  result_rdf(S, P, O, G),
  write_term(rdf(S, P, O, G), [quoted(true)]),
  write('.'),
  nl,
  fail.
write_results.
