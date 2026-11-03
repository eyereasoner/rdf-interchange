#!/usr/bin/env node
import { eyemindToRdfCli } from '../src/prolog-to-rdf.mjs';
eyemindToRdfCli().catch((error) => {
  process.stderr.write(`eyemind-to-rdf: ${error.message}\n`);
  process.exitCode = 1;
});
