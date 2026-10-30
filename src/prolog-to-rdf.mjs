import fs from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';
import { parseClauses } from './prolog-parser.mjs';
import { fromEyeProlog, quadToNQuad, quadsToTrig, quadsToTurtle } from './rdf-codec.mjs';

// Ground rdf/4 facts carry results. A result document that lists the answers
// of a result_rdf/4 query, as eyepl writes, carries them as result_rdf/4 facts.
const RESULT_PREDICATES = new Set(['rdf', 'result_rdf']);

export function extractRdfQuadsFromProlog(source) {
  const clauses = parseClauses(String(source), { sourceMetadata: false });
  const quads = [];
  const seen = new Set();
  for (const clause of clauses) {
    if (clause.body.length || !RESULT_PREDICATES.has(clause.head?.name) || clause.head?.arity !== 4) continue;
    const [subject, predicate, object, graph] = clause.head.args.map(fromEyeProlog);
    const quad = { subject, predicate, object, graph };
    const key = quadToNQuad(quad);
    if (!seen.has(key)) {
      seen.add(key);
      quads.push(quad);
    }
  }
  return quads;
}

export function extractRdfFromProlog(source) {
  const lines = extractRdfQuadsFromProlog(source).map(quadToNQuad);
  return lines.length ? `${lines.join('\n')}\n` : '';
}

export function serializeRdfFromProlog(source, { format = 'nq' } = {}) {
  const quads = extractRdfQuadsFromProlog(source);
  const normalized = normalizeFormat(format);
  if (normalized === 'ttl') return quadsToTurtle(quads);
  if (normalized === 'trig') return quadsToTrig(quads);
  const lines = quads.map(quadToNQuad);
  return lines.length ? `${lines.join('\n')}\n` : '';
}

// Compatibility alias for the original EyeProlog adapter API.
export const extractEyePrologRdf = extractRdfFromProlog;

export async function prologToRdfCli(argv = process.argv.slice(2)) {
  let input = '-'; let output = '-'; let format;
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '-h' || a === '--help') return usage();
    if (a === '-o' || a === '--output') output = required(argv, ++i, a);
    else if (a === '--format') format = required(argv, ++i, a);
    else if (a.startsWith('-') && a !== '-') throw new Error(`unknown option: ${a}`);
    else if (input === '-') input = a;
    else throw new Error(`unexpected argument: ${a}`);
  }
  const source = input === '-' ? await stdin() : await fs.readFile(input, 'utf8');
  const selectedFormat = format ?? inferFormat(output);
  const result = serializeRdfFromProlog(source, { format: selectedFormat });
  if (output === '-') process.stdout.write(result); else await fs.writeFile(output, result);
}

function inferFormat(output) {
  if (output === '-') return 'nq';
  const ext = path.extname(output).toLowerCase();
  if (ext === '.ttl') return 'ttl';
  if (ext === '.trig') return 'trig';
  return 'nq';
}

function normalizeFormat(format) {
  const value = String(format).toLowerCase().replace(/^\./, '');
  if (['ttl', 'turtle', 'text/turtle'].includes(value)) return 'ttl';
  if (['trig', 'application/trig'].includes(value)) return 'trig';
  if (['nq', 'nquads', 'n-quads', 'application/n-quads'].includes(value)) return 'nq';
  throw new Error(`unsupported RDF output format: ${format}`);
}

function usage() {
  process.stdout.write('Usage: prolog-to-rdf [options] [input.pl|-]\n\n  --format nq|ttl|trig  RDF output syntax (otherwise inferred from -o)\n  -o, --output FILE     Write RDF to FILE\n');
}
function required(a, i, o) { if (a[i] == null) throw new Error(`${o} requires a value`); return a[i]; }
function stdin() {
  return new Promise((resolve, reject) => {
    let s = '';
    process.stdin.setEncoding('utf8');
    process.stdin.on('data', (c) => { s += c; });
    process.stdin.on('end', () => resolve(s));
    process.stdin.on('error', reject);
  });
}
