import argparse
import csv
import json
from collections import defaultdict
from pathlib import Path


SUPPORTED_MODALITIES = {"face_verification", "liveness"}
SUPPORTED_LABELS = {"true_match", "false_match", "spoof", "poor_quality"}


def load_rows(input_file: Path) -> list[dict[str, str]]:
    with input_file.open("r", encoding="utf-8-sig", newline="") as file:
        reader = csv.DictReader(file)
        required_columns = {"sample_id", "modality", "primary_label", "normalized_score"}
        missing = required_columns.difference(reader.fieldnames or [])
        if missing:
            raise ValueError(f"Missing required columns: {sorted(missing)}")

        rows: list[dict[str, str]] = []
        for row in reader:
            modality = (row.get("modality") or "").strip()
            label = (row.get("primary_label") or "").strip()
            if modality not in SUPPORTED_MODALITIES:
                raise ValueError(f"Unsupported modality: {modality}")
            if label not in SUPPORTED_LABELS:
                raise ValueError(f"Unsupported primary_label: {label}")
            rows.append(row)

    if not rows:
        raise ValueError("Calibration input is empty.")

    return rows


def build_threshold_summary(rows: list[dict[str, str]]) -> dict[str, object]:
    grouped: dict[str, list[dict[str, str]]] = defaultdict(list)
    for row in rows:
        grouped[row["modality"]].append(row)

    output: dict[str, object] = {"modalities": {}}

    for modality, modality_rows in grouped.items():
        thresholds = sorted(
            {round(float(row["normalized_score"]), 6) for row in modality_rows},
            reverse=True,
        )

        label_positive_map = {
            "face_verification": {"true_match"},
            "liveness": {"true_match"},
        }
        positive_labels = label_positive_map[modality]

        evaluations = []
        for threshold in thresholds:
            tp = fp = tn = fn = 0

            for row in modality_rows:
                label = row["primary_label"]
                score = float(row["normalized_score"])
                predicted_positive = score >= threshold
                actual_positive = label in positive_labels

                if predicted_positive and actual_positive:
                    tp += 1
                elif predicted_positive and not actual_positive:
                    fp += 1
                elif not predicted_positive and actual_positive:
                    fn += 1
                else:
                    tn += 1

            fpr = fp / (fp + tn) if (fp + tn) else 0.0
            fnr = fn / (fn + tp) if (fn + tp) else 0.0
            precision = tp / (tp + fp) if (tp + fp) else 0.0
            recall = tp / (tp + fn) if (tp + fn) else 0.0
            balanced_error = (fpr + fnr) / 2.0

            evaluations.append(
                {
                    "threshold": threshold,
                    "tp": tp,
                    "fp": fp,
                    "tn": tn,
                    "fn": fn,
                    "falsePositiveRate": round(fpr, 6),
                    "falseNegativeRate": round(fnr, 6),
                    "precision": round(precision, 6),
                    "recall": round(recall, 6),
                    "balancedError": round(balanced_error, 6),
                }
            )

        best = min(evaluations, key=lambda item: (item["balancedError"], item["falsePositiveRate"]))

        output["modalities"][modality] = {
            "sampleCount": len(modality_rows),
            "recommendedThreshold": best["threshold"],
            "recommendedTradeoff": best,
            "allThresholds": evaluations,
        }

    return output


def render_markdown(summary: dict[str, object], input_file: Path) -> str:
    lines = [
        "# Calibration Report",
        "",
        "## Input",
        "",
        f"- Source file: `{input_file}`",
        "",
    ]

    modalities = summary.get("modalities", {})
    for modality_name, modality_summary in modalities.items():
        modality_summary = modality_summary  # type: ignore[assignment]
        recommended = modality_summary["recommendedTradeoff"]
        lines.extend(
            [
                f"## {modality_name}",
                "",
                f"- Sample count: `{modality_summary['sampleCount']}`",
                f"- Recommended threshold: `{modality_summary['recommendedThreshold']}`",
                f"- False positive rate: `{recommended['falsePositiveRate']}`",
                f"- False negative rate: `{recommended['falseNegativeRate']}`",
                f"- Precision: `{recommended['precision']}`",
                f"- Recall: `{recommended['recall']}`",
                f"- Balanced error: `{recommended['balancedError']}`",
                "",
                "### Threshold table",
                "",
                "| Threshold | TP | FP | TN | FN | FPR | FNR | Precision | Recall | Balanced Error |",
                "| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |",
            ]
        )

        for row in modality_summary["allThresholds"]:
            lines.append(
                f"| `{row['threshold']}` | `{row['tp']}` | `{row['fp']}` | `{row['tn']}` | `{row['fn']}` | "
                f"`{row['falsePositiveRate']}` | `{row['falseNegativeRate']}` | `{row['precision']}` | "
                f"`{row['recall']}` | `{row['balancedError']}` |"
            )

        lines.append("")

    return "\n".join(lines).rstrip() + "\n"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input-file", required=True)
    parser.add_argument("--output-json")
    parser.add_argument("--output-markdown")
    args = parser.parse_args()

    input_file = Path(args.input_file)
    rows = load_rows(input_file)
    summary = build_threshold_summary(rows)

    if args.output_json:
        Path(args.output_json).write_text(
            json.dumps(summary, ensure_ascii=False, indent=2),
            encoding="utf-8",
        )

    if args.output_markdown:
        Path(args.output_markdown).write_text(
            render_markdown(summary, input_file),
            encoding="utf-8",
        )

    print(json.dumps(summary, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
