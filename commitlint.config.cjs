module.exports = {
  extends: ["@commitlint/config-conventional"],
  rules: {
    "scope-empty": [2, "never"],
    "scope-enum": [
      2,
      "always",
      [
        "prompt",
        "action",
        "workflow",
        "gating",
        "examples",
        "notes",
        "docs",
        "readme",
        "deps",
        "ci",
        "release",
        "tooling",
        "tests",
        "security",
        "code",
      ],
    ],
  },
};
