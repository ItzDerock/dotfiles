{ ... }:
{
  home.file = {
    ".omp/agent/RULES.md".text = ''
      # Hard Rules

      - NEVER modify `README.md`, `CHANGELOG.md`, `LICENSE`, or any other top-level Markdown file unless I explicitly name that file in the request. Ask first if a change seems to require it.
    '';

    ".omp/agents/rules/tests.md".text = ''
      ---
      description: Writing or reviewing tests. Covers what not to test.
      globs: ["**/*.test.*", "**/*.spec.*", "**/tests/**", "**/test_*.py"]
      ---

      # Test Quality

      - Assert behavior, not literals. Skip any assertion whose only job is to restate a value already written in the source, for example `expect(VERSION).toBe("13.2")` against `export const VERSION = "13.2"`. It cannot fail for a real reason, so it is pure maintenance cost.
      - The same applies to constants, enums, config objects, and type-only surfaces. If the source line is the test, delete the test.
      - Every test should be able to name the bug it catches in one sentence. If you cannot, it does not earn its place.
      - Prefer one test per behavior over many near-identical cases that differ only in input value.
    '';
  };
}
