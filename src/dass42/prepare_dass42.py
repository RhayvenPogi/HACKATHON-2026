
from pathlib import Path
import pandas as pd
import numpy as np

RAW_FILE = Path("dataset/raw/dass42/data.csv")
OUTPUT_DIR = Path("dataset/processed/dass42")

OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

# Official DASS-42 item groupings
DEPRESSION_ITEMS = [
    3, 5, 10, 13, 16, 17, 21,
    24, 26, 31, 34, 37, 38, 42
]

ANXIETY_ITEMS = [
    2, 4, 7, 9, 15, 19, 20,
    23, 25, 28, 30, 36, 40, 41
]

STRESS_ITEMS = [
    1, 6, 8, 11, 12, 14, 18,
    22, 27, 29, 32, 33, 35, 39
]


def main():

    print("Loading DASS-42 dataset...")

    if not RAW_FILE.exists():
        raise FileNotFoundError(RAW_FILE)

    df = pd.read_csv(
        RAW_FILE,
        sep="\t",
        low_memory=False
    )

    # Verify required columns
    required = []

    for i in range(1, 43):
        required.extend([f"Q{i}A", f"Q{i}I"])

    missing = [
        column for column in required
        if column not in df.columns
    ]

    if missing:
        raise ValueError(
            f"Missing required columns: {missing}"
        )

    print("Original records:", len(df))

    # Extract answer and item identifier arrays
    answers = df[
        [f"Q{i}A" for i in range(1, 43)]
    ].to_numpy(dtype=float)

    item_ids = df[
        [f"Q{i}I" for i in range(1, 43)]
    ].to_numpy(dtype=float)

    if not np.isfinite(answers).all():
        raise ValueError("Missing or invalid answers found.")

    if not np.isfinite(item_ids).all():
        raise ValueError("Missing or invalid item IDs found.")

    if not np.all(np.isin(answers, [1, 2, 3, 4])):
        raise ValueError("Unexpected response values found.")

    # Validate randomized question identifiers
    expected = np.arange(1, 43)

    valid_rows = np.array([
        np.array_equal(
            np.sort(row.astype(int)),
            expected
        )
        and np.all(row == row.astype(int))
        for row in item_ids
    ])

    if not valid_rows.all():
        raise ValueError(
            f"{(~valid_rows).sum()} rows have invalid "
            "or duplicate question identifiers."
        )

    print("Question mapping validated.")

    # Reconstruct original questionnaire order.
    # Convert 1-4 responses into official 0-3 encoding.
    canonical = np.zeros(
        (len(df), 42),
        dtype=np.int8
    )

    row_indices = np.arange(len(df))[:, None]
    column_indices = item_ids.astype(int) - 1

    canonical[row_indices, column_indices] = (
        answers.astype(int) - 1
    )

    # Create clean dataset
    item_columns = [
        f"item_{i:02d}" for i in range(1, 43)
    ]

    clean = pd.DataFrame(
        canonical,
        columns=item_columns
    )

    # Calculate independent scale scores.
    # DASS-42 convention: multiply raw scores by 2.
    clean["depression_score"] = (
        clean[
            [f"item_{i:02d}" for i in DEPRESSION_ITEMS]
        ].sum(axis=1)
    )

    clean["anxiety_score"] = (
        clean[
            [f"item_{i:02d}" for i in ANXIETY_ITEMS]
        ].sum(axis=1)
    )

    clean["stress_score"] = (
        clean[
            [f"item_{i:02d}" for i in STRESS_ITEMS]
        ].sum(axis=1)
    )

    # Save processed data
    output_file = OUTPUT_DIR / "dass42_processed.csv"

    clean.to_csv(output_file, index=False)

    print("\nPREPROCESSING COMPLETE")
    print("Records:", len(clean))
    print("Questionnaire items:", len(item_columns))

    print("\nScore summary:")
    print(
        clean[
            [
                "depression_score",
                "anxiety_score",
                "stress_score"
            ]
        ].describe()
    )

    print("\nSaved to:", output_file)


if __name__ == "__main__":
    main()
