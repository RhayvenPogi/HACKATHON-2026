
from pathlib import Path
import pandas as pd
import json
from collections import Counter

# --------------------------------------------------
# CONFIGURATION
# --------------------------------------------------

BASE_DIR = Path("dataset/raw/goemotions/data")
OUTPUT_DIR = Path("dataset/processed/goemotions")

OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

SPLITS = {
    "train": BASE_DIR / "train.tsv",
    "validation": BASE_DIR / "dev.tsv",
    "test": BASE_DIR / "test.tsv"
}

EMOTIONS_FILE = BASE_DIR / "emotions.txt"

EXPECTED_LABEL_COUNT = 28


# --------------------------------------------------
# LOAD EMOTION LABELS
# --------------------------------------------------

def load_emotions():

    if not EMOTIONS_FILE.exists():
        raise FileNotFoundError(EMOTIONS_FILE)

    with open(EMOTIONS_FILE, "r", encoding="utf-8") as file:
        emotions = [
            line.strip()
            for line in file
            if line.strip()
        ]

    if len(emotions) != EXPECTED_LABEL_COUNT:
        raise ValueError(
            f"Expected 28 emotion labels, found {len(emotions)}"
        )

    if len(set(emotions)) != len(emotions):
        raise ValueError("Duplicate emotion names detected.")

    print("\nEmotion ID mapping:")

    for index, emotion in enumerate(emotions):
        print(f"{index}: {emotion}")

    return emotions


# --------------------------------------------------
# LOAD AND VALIDATE SPLIT
# --------------------------------------------------

def load_split(name, file_path, emotions):

    print(f"\nProcessing {name}...")

    if not file_path.exists():
        raise FileNotFoundError(file_path)

    df = pd.read_csv(
        file_path,
        sep="\t",
        header=None,
        names=["text", "labels", "id"],
        dtype=str,
        keep_default_na=False
    )

    print("Original records:", len(df))

    if df.empty:
        raise ValueError(f"{name} split is empty.")

    if not df["id"].is_unique:
        raise ValueError(f"Duplicate IDs found in {name}.")

    records = []
    label_counts = Counter()

    for index, row in df.iterrows():

        text = row["text"].strip()
        raw_labels = row["labels"].strip()
        record_id = row["id"].strip()

        if not text or not record_id or not raw_labels:
            raise ValueError(
                f"Empty field in {name}, row {index}"
            )

        try:
            label_ids = [
                int(value.strip())
                for value in raw_labels.split(",")
            ]
        except ValueError:
            raise ValueError(
                f"Invalid label ID in {name}, row {index}"
            )

        if len(label_ids) != len(set(label_ids)):
            raise ValueError(
                f"Duplicate labels in {name}, row {index}"
            )

        if any(
            label_id < 0 or label_id >= len(emotions)
            for label_id in label_ids
        ):
            raise ValueError(
                f"Out-of-range label ID in {name}, row {index}"
            )

        # Convert IDs into multi-hot vectors.
        multi_hot = [0] * len(emotions)

        for label_id in label_ids:
            multi_hot[label_id] = 1
            label_counts[emotions[label_id]] += 1

        records.append({
            "id": record_id,
            "text": text,
            "labels": multi_hot,
            "emotion_names": [
                emotions[label_id]
                for label_id in label_ids
            ]
        })

    # Save as JSON Lines for Hugging Face Datasets.
    output_file = OUTPUT_DIR / f"{name}.jsonl"

    with open(
        output_file,
        "w",
        encoding="utf-8"
    ) as file:

        for record in records:
            file.write(
                json.dumps(
                    record,
                    ensure_ascii=False
                ) + "\n"
            )

    print("Processed records:", len(records))
    print("Saved:", output_file)

    print("\nEmotion distribution:")

    for emotion, count in label_counts.most_common():
        print(f"{emotion}: {count}")

    return records


# --------------------------------------------------
# MAIN
# --------------------------------------------------

def main():

    print("=" * 60)
    print("GOEMOTIONS DATASET PREPROCESSING")
    print("=" * 60)

    emotions = load_emotions()

    processed = {}

    for split_name, file_path in SPLITS.items():

        processed[split_name] = load_split(
            split_name,
            file_path,
            emotions
        )

    # Check for overlapping record IDs.
    split_ids = {
        name: {record["id"] for record in records}
        for name, records in processed.items()
    }

    print("\nChecking split ID overlap...")

    names = list(split_ids)

    for i in range(len(names)):
        for j in range(i + 1, len(names)):

            overlap = (
                split_ids[names[i]]
                & split_ids[names[j]]
            )

            print(
                f"{names[i]} vs {names[j]}: "
                f"{len(overlap)} overlapping IDs"
            )

            if overlap:
                raise ValueError(
                    "Record IDs overlap between official splits."
                )

    print("\nChecking text overlap...")

    text_sets = {
        name: {
            record["text"]
            for record in records
        }
        for name, records in processed.items()
    }

    for i in range(len(names)):
        for j in range(i + 1, len(names)):

            overlap = (
                text_sets[names[i]]
                & text_sets[names[j]]
            )

            print(
                f"{names[i]} vs {names[j]}: "
                f"{len(overlap)} identical texts"
            )

    print("\n" + "=" * 60)
    print("PREPROCESSING COMPLETED")
    print("=" * 60)

    print("Training:", len(processed["train"]))
    print("Validation:", len(processed["validation"]))
    print("Testing:", len(processed["test"]))

    print("\nOutput directory:", OUTPUT_DIR)


if __name__ == "__main__":
    main()
