import childProcess from "node:child_process"
import { promisify } from "node:util"

const exec = promisify(childProcess.exec);

export const macOSVersions = new Map([
  ["Ventura", 13.0],
  ["Monterey", 12.0],
  ["Big Sur", 11.0],
  ["Catalina", 10.15],
  ["Mojave", 10.14],
  ["High Sierra", 10.13],
  ["Sierra", 10.12],
  ["El Capitan", 10.11],
  ["Yosemite", 10.1],
])

export async function getMacOSVersion() {
  const result = await exec("sw_vers -productVersion");

  const currentVersion = parseFloat(result.stdout.trim());

  const releaseName = [...macOSVersions].find(([name, version]) => currentVersion >= version)[0]

  return { currentVersion, releaseName };
}
