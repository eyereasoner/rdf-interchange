#!/usr/bin/env node
import { rdfToEyemindCli } from '../src/rdf-to-prolog.mjs';
rdfToEyemindCli().catch((error) => {
  process.stderr.write(`rdf-to-eyemind: ${error.message}\n`);
  process.exitCode = 1;
});
