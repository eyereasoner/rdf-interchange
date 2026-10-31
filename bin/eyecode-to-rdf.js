#!/usr/bin/env node
import { eyecodeToRdfCli } from '../src/prolog-to-rdf.mjs';
eyecodeToRdfCli().catch((error) => {
  process.stderr.write(`eyecode-to-rdf: ${error.message}\n`);
  process.exitCode = 1;
});
