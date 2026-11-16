import contextlib
import importlib.util
import io
import json
from pathlib import Path
import tempfile
import unittest


spec = importlib.util.spec_from_file_location(
    "marketplace", Path(__file__).resolve().parents[1] / "scripts/sync-cursor-marketplace.py"
)
marketplace = importlib.util.module_from_spec(spec)
spec.loader.exec_module(marketplace)


class MarketplaceTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)

    def skill(self, folder, metadata):
        path = self.root / marketplace.SKILLS / folder / "SKILL.md"
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(f"---\n{metadata}\n---\n# Instructions\n")
        return path

    def sync(self, check=False):
        with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            return marketplace.sync(self.root, check=check)

    def catalog(self):
        return json.loads((self.root / marketplace.MARKETPLACE).read_text())

    def test_real_yaml_root_skill_and_bundled_resources(self):
        skill = self.skill("sample", 'name: sample\ndescription: >-\n  A multiline description:\n  with "quotes" and Unicode café.')
        reference = skill.parent / "references/example.md"
        reference.parent.mkdir()
        reference.write_text("reference content")
        self.assertFalse(self.sync(check=True))
        self.assertFalse((self.root / marketplace.MARKETPLACE).exists())
        self.sync()
        entry = self.catalog()["plugins"][0]
        self.assertEqual(entry["description"], 'A multiline description: with "quotes" and Unicode café.')
        self.assertEqual(self.root / entry["source"], skill.parent)
        manifest = skill.parent / ".cursor-plugin/plugin.json"
        self.assertEqual(json.loads(manifest.read_text())["name"], "sample")
        self.assertNotIn("skills", json.loads(manifest.read_text()))
        before = {p: p.read_bytes() for p in self.root.rglob("*") if p.is_file()}
        self.sync()
        self.assertTrue(self.sync(check=True))
        self.assertEqual(before, {p: p.read_bytes() for p in self.root.rglob("*") if p.is_file()})

    def test_add_edit_rename_and_remove(self):
        first = self.skill("a", "name: a\ndescription: First")
        self.sync()
        self.skill("b", "name: b\ndescription: Second")
        self.sync()
        self.assertEqual([p["name"] for p in self.catalog()["plugins"]], ["a", "b"])
        self.skill("a", "name: renamed\ndescription: Updated")
        self.assertFalse(self.sync(check=True))
        self.sync()
        self.assertEqual(self.catalog()["plugins"][0]["name"], "renamed")
        first.unlink()
        self.assertFalse(self.sync(check=True))
        self.sync()
        self.assertEqual([p["name"] for p in self.catalog()["plugins"]], ["b"])
        self.assertFalse((first.parent / ".cursor-plugin/plugin.json").exists())

    def test_invalid_input_never_partially_updates_metadata(self):
        self.skill("a", "name: a\ndescription: Valid")
        self.sync()
        before = (self.root / marketplace.MARKETPLACE).read_bytes()
        for metadata in ["name: a\ndescription: Duplicate", "name: bad_name\ndescription: Invalid",
                         "name: b\ndescription: []", "[not, a, mapping]", "name: ["]:
            with self.subTest(metadata=metadata):
                self.skill("b", metadata)
                with self.assertRaises((ValueError, marketplace.yaml.YAMLError)):
                    self.sync()
                self.assertEqual(before, (self.root / marketplace.MARKETPLACE).read_bytes())
                self.assertFalse((self.root / marketplace.SKILLS / "b/.cursor-plugin").exists())

    def test_missing_source_does_not_create_empty_catalog(self):
        with self.assertRaises(ValueError):
            self.sync()
        self.assertFalse((self.root / marketplace.MARKETPLACE).exists())

    def test_unavailable_external_skill_is_omitted(self):
        self.skill("sample", "name: sample\ndescription: Available")
        external = self.root / marketplace.SKILLS / "external/SKILL.md"
        external.parent.mkdir()
        external.symlink_to(self.root / "missing-app/SKILL.md")
        self.sync()
        self.assertEqual([p["name"] for p in self.catalog()["plugins"]], ["sample"])
        self.assertTrue(self.sync(check=True))


if __name__ == "__main__":
    unittest.main()
