import childProcess from "node:child_process";
import { promisify } from "node:util";

const exec = promisify(childProcess.exec);

export const macOSVersions = new Map([
  ["Sequoia", "15.0"],
  ["Sonoma", "14.0"],
  ["Ventura", "13.0"],
  ["Monterey", "12.0"],
  ["Big Sur", "11.0"],
  ["Catalina", "10.15"],
  ["Mojave", "10.14"],
  ["High Sierra", "10.13"],
  ["Sierra", "10.12"],
  ["El Capitan", "10.11"],
  ["Yosemite", "10.1"],
]);

export async function getMacOSVersion() {
  const result = await exec("sw_vers -productVersion");

  const currentVersion = result.stdout.trim();

  // find the release name for the current version of macOS
  // if big sur or newer, only use the major version number
  // otherwise, use the full version number
  // if the version number is not found, use "Unknown"
  let releaseName = "Unknown";
  for (const [name, version] of macOSVersions) {
    if (version.endsWith(".0")) {
      let [currentMajorVersion] = currentVersion.split(".");
      let [majorVersion] = version.split(".");
      if (currentMajorVersion === majorVersion) {
        releaseName = name;
        break;
      }
    } else {
      if (currentVersion === version) {
        releaseName = name;
        break;
      }
    }
  }

  return { currentVersion, releaseName };
}
