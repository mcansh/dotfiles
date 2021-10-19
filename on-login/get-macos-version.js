const childProcess = require("child_process");
const { promisify } = require("util");

const exec = promisify(childProcess.exec);

const macOSVersions = {
  Monterey: 12.0,
  "Big Sur": 11.0,
  Catalina: 10.15,
  Mojave: 10.14,
  "High Sierra": 10.13,
  Sierra: 10.12,
  "El Capitan": 10.11,
  Yosemite: 10.1,
};

async function getMacOSVersion() {
  const result = await exec("sw_vers -productVersion");

  const currentVersion = parseFloat(result.stdout.trim());

  const releaseName = macOSVersions[currentVersion];

  return { currentVersion, releaseName };
}

module.exports = { getMacOSVersion, macOSVersions };
