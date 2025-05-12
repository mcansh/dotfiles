import cp from "node:child_process";

/** @returns {Array<{major: number, minor: number, patch: number}>} */
function getNodeVersions() {
	// get all the installed node versions
	let nodeVersionString = cp.execSync(`n list`, { encoding: "utf-8" });

	// split by new line and remove empty strings
	let lines = nodeVersionString
		.split("\n")
		.map((n) => n.trim())
		.filter(Boolean);

	let versions = lines.map((n) => {
		let version = n.split("node/").at(1);
		// split into major, minor, patch
		let [major, minor, patch] = version.split(".").map((p) => Number(p));
		return { major, minor, patch };
	});

	// sort by major then minor
	return versions.sort((a, b) => {
		return b.major - a.major || b.minor - a.minor || b.patch - a.patch;
	});
}

let nodeVersions = getNodeVersions();

/**
 * @description map of major versions
 * @type {Map<string, string[]>}
 */
let versionMap = nodeVersions.reduce((acc, version) => {
	let key = version.major;
	acc.set(key, acc.get(key) || []);
	let merged = [
		...acc.get(key),
		`${version.major}.${version.minor}.${version.patch}`,
	];

	acc.set(key, merged);
	return acc;
}, new Map());

// loop over the major versions
// keep the latest version
// delete the rest
for (let [major, versions] of versionMap) {
	let nonLatestVersions = versions.slice(1);

	if (nonLatestVersions.length === 0) {
		console.log(`keeping latest Node v${major} version`);
		continue;
	}
	console.log(
	  `removing Node v${major}.x versions: ${nonLatestVersions.join(", ")}`
  );
	cp.execSync(`n rm ${nonLatestVersions.join(' ')}`);
}
