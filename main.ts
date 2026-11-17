// Brainrot Bazaar hands itself in through this program (Node 22, standard
// library only). The game is the Rojo project beside this file: its scripts
// live under src/, its world and scripts are packed into game.rbxl by
// `rojo build default.project.json --output game.rbxl`, and this program
// copies the place file, the sources, the screenshots and PLAY.json into the
// output directory, then writes dossier.json with the vendored make.fun
// library, which is the summary the judge reads.
//
// The grader refuses any output name that does not start with a letter, a
// digit or an underscore, so the directory copies below skip every name
// starting with a dot, at any depth: no .gitkeep, no .DS_Store, no .git.
//
// Outside the grader, MAKEFUN_OUTPUT_DIR stands in for /output:
//   mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

import { copyFileSync, cpSync, existsSync, mkdirSync, writeFileSync } from "node:fs";
import { basename, join } from "node:path";
import { fileURLToPath } from "node:url";
import { buildDossier } from "./vendor/makefun-roblox.ts";

const repoRoot = fileURLToPath(new URL(".", import.meta.url));
const outputDir = process.env.MAKEFUN_OUTPUT_DIR ?? "/output";

/** cpSync filter: drop every file and directory whose name starts with a dot. */
const keepIfNotDotted = (path: string): boolean => !basename(path).startsWith(".");

copyFileSync(join(repoRoot, "game.rbxl"), join(outputDir, "game.rbxl"));
copyFileSync(join(repoRoot, "PLAY.json"), join(outputDir, "PLAY.json"));
cpSync(join(repoRoot, "src"), join(outputDir, "src"), { recursive: true, filter: keepIfNotDotted });
mkdirSync(join(outputDir, "screenshots"), { recursive: true });
if (existsSync(join(repoRoot, "screenshots"))) {
	cpSync(join(repoRoot, "screenshots"), join(outputDir, "screenshots"), { recursive: true, filter: keepIfNotDotted });
}

// The scorer's own caps, as the kit's reference gate.json states them. Only
// text_max_bytes shapes the dossier bytes; the rest refuse an entry the
// scorer would refuse (too many or too large screenshots, a place past its
// instance, script-source or script-path caps).
writeFileSync(
	join(outputDir, "dossier.json"),
	buildDossier(outputDir, {
		text_max_bytes: 65536,
		screenshots: { max: 4, max_bytes: 262144 },
		max_instances: 500000,
		scripts_max_source_bytes: 8388608,
		scripts_max_path_chars: 1048576,
	}),
);
