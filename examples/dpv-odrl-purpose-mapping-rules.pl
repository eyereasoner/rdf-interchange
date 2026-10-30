% The DPV process and ODRL policy are RDF data. The rules verify the six
% correspondences and return one deterministic mapping report.
%% goal: result_rdf(_, _, _, _)

% These helpers are called with some arguments known. Tabling evaluates them
% on demand, also in engines that otherwise run rules forward.
:- table iri_term/2.
:- table rdf_link/3.
:- table mapping_value_iri/3.
:- table mapping_target_iri/2.

dpv_odrl_purpose_mapping(Mappings) :-
  findall(
    mapping(SourceRole, Value, TargetRole),
    mapped_role(SourceRole, Value, TargetRole),
    Mappings
  ).

mapped_role(data_controller, Controller, assigner) :-
  rdf_link(ex(alpha_care_process), dpv(hasDataController), ex(Controller)),
  rdf_link(ex(alpha_permission), odrl(assigner), ex(Controller)).

mapped_role(recipient, Recipient, assignee) :-
  rdf_link(ex(alpha_care_process), dpv(hasRecipient), ex(Recipient)),
  rdf_link(ex(alpha_permission), odrl(assignee), ex(Recipient)).

mapped_role(personal_data, Data, target) :-
  rdf_link(ex(alpha_care_process), dpv(hasPersonalData), ex(Data)),
  rdf_link(ex(alpha_permission), odrl(target), ex(Data)).

mapped_role(processing, dpv_use, action) :-
  rdf_link(ex(alpha_care_process), dpv(hasProcessing), dpv('Use')),
  rdf_link(ex(alpha_permission), odrl(action), odrl(use)).

mapped_role(purpose, dpv_healthcare, constraint(alpha_purpose_constraint)) :-
  rdf_link(ex(alpha_care_process), dpv(hasPurpose), dpv('Healthcare')),
  odrl_constraint(alpha_purpose_constraint, odrl(purpose), dpv('Healthcare')).

mapped_role(legal_basis, dpv_consent, constraint(alpha_basis_constraint)) :-
  rdf_link(ex(alpha_care_process), dpv(hasLegalBasis), dpv('Consent')),
  odrl_constraint(alpha_basis_constraint, ex(legalBasis), dpv('Consent')).

odrl_constraint(Name, LeftOperand, RightOperand) :-
  rdf_link(ex(alpha_permission), odrl(constraint), ex(Name)),
  rdf_link(ex(Name), odrl('leftOperand'), LeftOperand),
  rdf_link(ex(Name), odrl(operator), odrl('isA')),
  rdf_link(ex(Name), odrl('rightOperand'), RightOperand).

rdf_link(Subject, Predicate, Object) :-
  iri_term(Subject, SubjectIri),
  iri_term(Predicate, PredicateIri),
  rdf(iri(SubjectIri), iri(PredicateIri), iri(ObjectIri), default_graph),
  iri_term(Object, ObjectIri).

iri_term(ex(Name), Iri) :- namespace_iri('https://example.org/', Name, Iri).
iri_term(dpv(Name), Iri) :- namespace_iri('https://w3id.org/dpv#', Name, Iri).
iri_term(odrl(Name), Iri) :- namespace_iri('http://www.w3.org/ns/odrl/2/', Name, Iri).

namespace_iri(Prefix, Name, Iri) :- atom_concat(Prefix, Name, Iri).

% RDF form of every verified DPV -> ODRL mapping.
result_rdf(iri(Node), iri('https://example.org/sourceRole'), iri(RoleIri), default_graph) :-
  mapped_role(Role, _Value, _Target),
  mapping_node(Role, Node),
  mapping_role_iri(Role, RoleIri).
result_rdf(iri(Node), iri('https://example.org/value'), iri(ValueIri), default_graph) :-
  mapped_role(Role, Value, _Target),
  mapping_node(Role, Node),
  mapping_value_iri(Role, Value, ValueIri).
result_rdf(iri(Node), iri('https://example.org/mappingTarget'), iri(TargetIri), default_graph) :-
  mapped_role(Role, _Value, Target),
  mapping_node(Role, Node),
  mapping_target_iri(Target, TargetIri).

mapping_node(Role, Iri) :- atom_concat('https://example.org/result/mapping/', Role, Iri).
mapping_role_iri(Role, Iri) :- atom_concat('https://example.org/role/', Role, Iri).

mapping_value_iri(data_controller, Value, Iri) :- iri_term(ex(Value), Iri).
mapping_value_iri(recipient, Value, Iri) :- iri_term(ex(Value), Iri).
mapping_value_iri(personal_data, Value, Iri) :- iri_term(ex(Value), Iri).
mapping_value_iri(processing, dpv_use, Iri) :- iri_term(dpv('Use'), Iri).
mapping_value_iri(purpose, dpv_healthcare, Iri) :- iri_term(dpv('Healthcare'), Iri).
mapping_value_iri(legal_basis, dpv_consent, Iri) :- iri_term(dpv('Consent'), Iri).

mapping_target_iri(assigner, Iri) :- iri_term(odrl(assigner), Iri).
mapping_target_iri(assignee, Iri) :- iri_term(odrl(assignee), Iri).
mapping_target_iri(target, Iri) :- iri_term(odrl(target), Iri).
mapping_target_iri(action, Iri) :- iri_term(odrl(action), Iri).
mapping_target_iri(constraint(Name), Iri) :- iri_term(ex(Name), Iri).

% ISO Prolog helper: print the complete test result as rdf/4 facts.
write_results :-
  result_rdf(S, P, O, G),
  write_term(rdf(S, P, O, G), [quoted(true)]),
  write('.'),
  nl,
  fail.
write_results.
