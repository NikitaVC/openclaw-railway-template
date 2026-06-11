import fs from "node:fs";
import path from "node:path";

const stateDir = process.env.OPENCLAW_STATE_DIR?.trim() || "/data/.openclaw";
const configPath = process.env.OPENCLAW_CONFIG_PATH?.trim() || path.join(stateDir, "openclaw.json");

function log(message) {
  console.log(`[entrypoint:migrate] ${message}`);
}

if (fs.existsSync(configPath)) {
  const raw = fs.readFileSync(configPath, "utf8");
  const config = JSON.parse(raw);
  let changed = false;

  const models = config?.agents?.defaults?.models;
  const codexModel = models?.["openai/gpt-5.3-codex"];
  if (codexModel && Object.prototype.hasOwnProperty.call(codexModel, "agentRuntime")) {
    delete codexModel.agentRuntime;
    if (Object.keys(codexModel).length === 0) delete models["openai/gpt-5.3-codex"];
    changed = true;
    log("removed deprecated agents.defaults.models.openai/gpt-5.3-codex.agentRuntime");
  }

  const telegram = config?.channels?.telegram;
  if (telegram && typeof telegram.streaming === "object") {
    const mode = telegram.streaming?.mode;
    telegram.streaming = ["off", "partial", "block", "progress"].includes(mode) ? mode : "partial";
    changed = true;
    log(`normalized channels.telegram.streaming to ${JSON.stringify(telegram.streaming)}`);
  }

  if (changed) {
    const backupPath = `${configPath}.bak-${new Date().toISOString().replace(/[-:T.Z]/g, "").slice(0, 14)}-startup-migrate`;
    fs.writeFileSync(backupPath, raw, { mode: 0o600 });
    fs.writeFileSync(configPath, `${JSON.stringify(config, null, 2)}\n`, { mode: 0o600 });
    log(`saved backup ${backupPath}`);
  } else {
    log("no config migration needed");
  }
}
