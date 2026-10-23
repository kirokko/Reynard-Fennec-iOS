// Manual analysis of completed runs; never dispatches builds or downloads an old IPA.
import fs from 'node:fs';
import { execFileSync } from 'node:child_process';
const repo = process.env.GITHUB_REPOSITORY || 'kirokko/Reynard-Fennec-iOS';
const [output, ...ids] = process.argv.slice(2);
if (!output || !ids.length) throw Error('Usage: node tools/ci/Report-BuildPerformance.mjs output.json run-id...');
const api = suffix => JSON.parse(execFileSync('gh', ['api', `repos/${repo}/${suffix}`], { encoding: 'utf8', maxBuffer: 16 * 1024 * 1024 }));
const seconds = (a, b) => Math.round((new Date(b) - new Date(a)) / 1000);
const results = [];
for (const id of ids) {
  const run = api(`actions/runs/${id}`), jobs = api(`actions/runs/${id}/jobs?per_page=100`).jobs;
  const job = jobs.find(j => j.name.includes('Build standard engine'));
  if (!job) throw Error(`No standard build job: ${id}`);
  const steps = job.steps.map(s => ({ name: s.name, conclusion: s.conclusion, seconds: s.started_at && s.completed_at ? seconds(s.started_at, s.completed_at) : null }));
  const upload = job.steps.find(s => s.name === 'Upload IPA' && s.conclusion === 'success');
  const find = part => steps.find(s => s.name.includes(part));
  const native = find('Build idevice support library');
  const gecko = find('Build Gecko on SDK miss') || steps.find(s => s.name === 'Build Gecko');
  results.push({
    run: Number(id), number: run.run_number, url: run.html_url,
    ref: run.head_branch, commit: run.head_sha, conclusion: run.conclusion,
    jobSeconds: seconds(job.started_at, job.completed_at),
    dispatchToDownloadSeconds: upload ? seconds(run.created_at, upload.completed_at) : null,
    cacheEvidence: { geckoCompilation: gecko?.conclusion, ideviceCompilation: native?.conclusion, xcodeRestoreSeconds: find('Restore compatible Xcode')?.seconds ?? null },
    steps,
  });
}
fs.writeFileSync(output, JSON.stringify(results, null, 2) + '\n');
for (const r of results) console.log(`#${r.number} ${r.conclusion} job=${r.jobSeconds}s dispatch->IPA=${r.dispatchToDownloadSeconds ?? 'NO IPA'}s ${r.commit}`);
