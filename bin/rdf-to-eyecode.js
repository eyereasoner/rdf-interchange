#!/usr/bin/env node
import { rdfToEyecodeCli } from '../src/rdf-to-prolog.mjs';
rdfToEyecodeCli().catch((error) => {
  process.stderr.write(`rdf-to-eyecode: ${error.message}\n`);
  process.exitCode = 1;
});
