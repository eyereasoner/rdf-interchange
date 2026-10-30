# Examples

There are 14 examples. They are deliberately flat: every example is the same
five-file pipeline.

```text
<name>-input.ttl|trig   RDF input
<name>-input.pl         rdf-to-prolog result
<name>-rules.pl         Prolog rules
<name>-output.pl        Prolog test result as ground rdf/4 facts
<name>-output.ttl|trig  prolog-to-rdf result
```

Every `*-rules.pl` exposes the same two predicates:

```prolog
result_rdf(S, P, O, G).  % enumerate the result
write_results.           % print every result as an rdf/4 fact
```

## Example: trust flow

The five files are:

```text
odrl-dpv-fpv-trust-flow-input.ttl
odrl-dpv-fpv-trust-flow-input.pl
odrl-dpv-fpv-trust-flow-rules.pl
odrl-dpv-fpv-trust-flow-output.pl
odrl-dpv-fpv-trust-flow-output.ttl
```

Regenerate the input Prolog facts:

```sh
rdf-to-prolog examples/odrl-dpv-fpv-trust-flow-input.ttl \
  -o examples/odrl-dpv-fpv-trust-flow-input.pl
```

Load the input and rules in a Prolog engine and query:

```prolog
?- result_rdf(S, P, O, G).
```

Or run `write_results/0` to print the complete result as `rdf/4` facts. With
EyeProlog 1.5.26 or newer, `--quiet` keeps the resolved command goal out of the
materialized fact stream:

```sh
eyeprolog --quiet --goal write_results \
  examples/odrl-dpv-fpv-trust-flow-input.pl \
  examples/odrl-dpv-fpv-trust-flow-rules.pl \
  > examples/odrl-dpv-fpv-trust-flow-output.pl
```

The same rules can, for example, be materialized with SWI-Prolog:

```sh
swipl -q \
  -s examples/odrl-dpv-fpv-trust-flow-input.pl \
  -s examples/odrl-dpv-fpv-trust-flow-rules.pl \
  -g write_results -t halt \
  > examples/odrl-dpv-fpv-trust-flow-output.pl
```

Only the command-line flags are host-specific.

eyepl evaluates the same rules and lists the answers of the query as
`result_rdf/4` facts:

```sh
printf '?- result_rdf(S, P, O, G).\n' > query.pl
eyepl examples/odrl-dpv-fpv-trust-flow-input.pl \
  examples/odrl-dpv-fpv-trust-flow-rules.pl query.pl
```

The rules are ISO Prolog with two widely supported additions. Four examples
declare `:- table` for helpers that are called with some arguments already
known, and three rank results with `aggregate_all(count, Goal, Count)`.
EyeProlog, SWI-Prolog, and eyepl run all 14 examples. A table declaration
evaluates a helper on demand; engines that otherwise run rules forward, such as
eyepl, need it for helpers that cannot start without those arguments.

Convert the Prolog result back to RDF:

```sh
prolog-to-rdf examples/odrl-dpv-fpv-trust-flow-output.pl \
  -o examples/odrl-dpv-fpv-trust-flow-output.ttl
```

For TriG inputs, the final filename is `*-output.trig` and named graphs are
preserved.
