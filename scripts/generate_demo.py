"""Generate illustrative curves without reading or fitting participant data."""
import csv
import hashlib
from pathlib import Path


def write_demo(destination):
    destination = Path(destination)
    destination.parent.mkdir(parents=True, exist_ok=True)
    with destination.open("w", newline="", encoding="utf-8") as stream:
        writer = csv.writer(stream, lineterminator="\n")
        writer.writerow(["trajectory", "condition", "move", "tally"])
        for condition, horizon in [("reference_a", 24), ("reference_b", 35)]:
            for trial in range(1, 101):
                # Hash ordering makes the fixture independent of Python RNG versions.
                candidates = list(range(1, horizon + 1))
                fruit_moves = set(sorted(candidates, key=lambda move: hashlib.sha256(
                    f"foraging-synthetic-v1:{condition}:{trial}:{move}".encode()
                ).digest())[:10])
                for move in range(36):
                    writer.writerow([f"synthetic-{condition}-{trial}", condition, move,
                                     sum(found <= move for found in fruit_moves)])


if __name__ == "__main__":
    write_demo(Path(__file__).resolve().parents[1] / "data/synthetic-curves.csv")
