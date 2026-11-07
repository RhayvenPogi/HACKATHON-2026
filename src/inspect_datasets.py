
from pathlib import Path
import pandas as pd

DASS_DIR = Path("dataset/raw/dass42")
GOEMOTIONS_DIR = Path("dataset/raw/goemotions/data")


def inspect_dass42():
    print("\n" + "=" * 65)
    print("DASS-42 DATASET")
    print("=" * 65)

    file = DASS_DIR / "data.csv"

    if not file.exists():
        print("DASS-42 data.csv not found.")
        return

    # IMPORTANT: DASS file is tab-separated.
    df = pd.read_csv(file, sep="\t", low_memory=False)

    print("Total records:", len(df))
    print("Total columns:", len(df.columns))

    answer_columns = [
        f"Q{i}A" for i in range(1, 43)
    ]

    item_columns = [
        f"Q{i}I" for i in range(1, 43)
    ]

    missing_columns = [
        c for c in answer_columns + item_columns
        if c not in df.columns
    ]

    if missing_columns:
        print("Missing expected columns:", missing_columns)
        return

    print("\nAnswer value distributions:")

    answers = df[answer_columns]

    print(answers.describe())

    print("\nUnique answer values:")
    print(
        pd.unique(
            answers.to_numpy().ravel()
        )
    )

    print("\nQuestion item identifier ranges:")

    items = df[item_columns]

    print(items.describe())

    print("\nFirst respondent's answer-to-item mapping:")

    for i in range(1, 43):
        print(
            f"Answer {i}: "
            f"Item {df.iloc[0][f'Q{i}I']} "
            f"= {df.iloc[0][f'Q{i}A']}"
        )

    print("\nMissing values in questionnaire:")
    print(
        df[answer_columns + item_columns]
        .isnull()
        .sum()
    )

    print("\nDataset inspection complete.")


def inspect_goemotions():
    print("\n" + "=" * 65)
    print("GOEMOTIONS DATASET")
    print("=" * 65)

    splits = ["train.tsv", "dev.tsv", "test.tsv"]

    for filename in splits:

        file = GOEMOTIONS_DIR / filename

        if not file.exists():
            print(filename, "not found.")
            continue

        # Official TSV files have no header.
        df = pd.read_csv(
            file,
            sep="\t",
            header=None,
            names=["text", "labels", "id"],
            dtype=str
        )

        print("\nFILE:", filename)
        print("Records:", len(df))
        print("Columns:", df.columns.tolist())

        print("\nFirst five records:")
        print(df.head().to_string(index=False))

        print("\nMissing values:")
        print(df.isnull().sum())

        print("\nSample label values:")
        print(df["labels"].head(10).tolist())

    print("\nInspecting CSV annotation files...")

    for file in sorted(GOEMOTIONS_DIR.glob("goemotions_*.csv")):

        df = pd.read_csv(file, nrows=5)

        emotion_columns = [
            c for c in df.columns
            if c in [
                "admiration", "amusement", "anger",
                "annoyance", "approval", "caring",
                "confusion", "curiosity", "desire",
                "disappointment", "disapproval", "disgust",
                "embarrassment", "excitement", "fear",
                "gratitude", "grief", "joy", "love",
                "nervousness", "optimism", "pride",
                "realization", "relief", "remorse",
                "sadness", "surprise", "neutral"
            ]
        ]

        print("\nFILE:", file.name)
        print("Preview columns:", len(df.columns))
        print("Emotion columns:", len(emotion_columns))
        print("Emotion labels:", emotion_columns)


def main():
    inspect_dass42()
    inspect_goemotions()


if __name__ == "__main__":
    main()
