import cp from "node:child_process";
import { promisify } from "node:util";

const execFile = promisify(cp.execFile);

/** @returns {Array<{major: number, minor: number, patch: number, active: boolean}>} */
function getNodeVersions() {
  // get all the installed node versions
  let nodeVersionString = cp.execFileSync("nub", ["node", "ls"], { encoding: "utf-8" });

  // split by new line and remove empty strings
  let lines = nodeVersionString
    .split("\n")
    .map((n) => n.trim())
    .filter((line) => /^(?:→\s*)?\d+\.\d+\.\d+$/.test(line));

  let versions = lines.map((n) => {
    let version = n.replace(/^→\s*/, "");
    // split into major, minor, patch
    let [major, minor, patch] = version.split(".").map((p) => Number(p));
    return { major, minor, patch, active: n.startsWith("→") };
  });

  // sort by major then minor
  return versions.sort((a, b) => {
    return b.major - a.major || b.minor - a.minor || b.patch - a.patch;
  });
}

let nodeVersions = getNodeVersions();

// Download the latest release for each major version in parallel.
const majorVersions = [...new Set(nodeVersions.map((version) => version.major))];

const downloads = await Promise.allSettled(
  majorVersions.map(async (major) => {
    console.log(`downloading latest Node v${major}`);
    await execFile("nub", ["node", "install", String(major)]);
    console.log(`downloaded latest Node v${major}`);
  }),
);

const failures = downloads.filter((download) => download.status === "rejected");
if (failures.length) {
  throw new AggregateError(
    failures.map((failure) => failure.reason),
    "Node downloads failed; skipping cleanup",
  );
}

nodeVersions = getNodeVersions();

/** @type {Map<number, string[]>} */
const versionMap = new Map();
for (const { major, minor, patch } of nodeVersions) {
  if (!versionMap.has(major)) versionMap.set(major, []);
  versionMap.get(major).push(`${major}.${minor}.${patch}`);
}

// loop over the major versions
// keep the latest version
// delete the rest
for (let [major, versions] of versionMap) {
  let nonLatestVersions = versions.slice(1).filter((version) =>
    !nodeVersions.some((node) => node.active && `${node.major}.${node.minor}.${node.patch}` === version),
  );

  if (nonLatestVersions.length === 0) {
    console.log(`keeping latest Node v${major} version: ${versions.at(0)}`);
    continue;
  }
  console.log(`removing Node v${major}.x versions: ${nonLatestVersions.join(", ")}`);
  for (const version of nonLatestVersions) {
    cp.execFileSync("nub", ["node", "uninstall", version], { stdio: "inherit" });
  }
}
