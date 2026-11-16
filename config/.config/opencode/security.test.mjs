import assert from "node:assert/strict";
import test from "node:test";
import { tool } from "@opencode-ai/plugin";
import { Effect, Result } from "effect";
import { Cookies } from "effect/unstable/http";
import toml from "toml";

test("OpenCode tools retain schema validation and execution", async () => {
  const greeting = tool({
    description: "Greet a user",
    args: { name: tool.schema.string().min(1) },
    execute: async ({ name }) => Effect.runSync(Effect.succeed(`Hello ${name}`)),
  });
  const args = tool.schema.object(greeting.args);
  assert.equal(await greeting.execute(args.parse({ name: "Logan" })), "Hello Logan");
  assert.equal(args.safeParse({ name: "" }).success, false);
});

test("oversized constrained arrays stop before validating their elements", () => {
  const result = tool.schema.array(tool.schema.string()).max(1).safeParse([0, 0]);
  assert.equal(result.success, false);
  assert.deepEqual(result.error.issues.map(({ code }) => code), ["too_big"]);
});

test("cookies reject injected attributes in names, domains, and paths", () => {
  assert.equal(
    Cookies.serializeCookie(Cookies.makeCookieUnsafe("session", "value", { domain: "example.com", path: "/" })),
    "session=value; Domain=example.com; Path=/",
  );
  for (const [name, options] of [
    ["session; SameSite=None", {}],
    ["session", { domain: "example.com; Domain=parent.test" }],
    ["session", { path: "/; SameSite=None" }],
  ]) {
    assert.equal(Result.isFailure(Cookies.makeCookie(name, "value", options)), true);
  }
});

test("TOML preserves ordinary config and rejects unsafe integers and excessive nesting", () => {
  const config = toml.parse('enabled = true\n[[servers]]\nname = "local"\nport = 8080');
  assert.equal(config.enabled, true);
  assert.equal(config.servers[0].name, "local");
  assert.equal(config.servers[0].port, 8080);
  assert.throws(() => toml.parse("value = 9007199254740993"));
  assert.throws(
    () => toml.parse(`value = ${"[".repeat(501)}0${"]".repeat(501)}`),
    (error) => error instanceof Error && !(error instanceof RangeError),
  );
});

test("TOML prototype keys do not modify Object.prototype", () => {
  toml.parse("__proto__.opencodeSecurityProbe = true");
  assert.equal(Object.hasOwn(Object.prototype, "opencodeSecurityProbe"), false);
  assert.equal({}.opencodeSecurityProbe, undefined);
});
