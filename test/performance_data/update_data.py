#!/usr/bin/env python3
"""Update script that fetches new performance data and merges it with existing data."""
import sys
import json
import subprocess
from io import StringIO
import pandas as pd

from config import JSON_CACHE, CSV_FILE as CSV_OUT, REPO, STEP_NAME


def run_gh_command(args):
    """Run a GitHub CLI command and return the output."""
    cmd = ["gh"] + args
    try:
        result = subprocess.run(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            check=True
        )
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        print(f"❌ Error running gh command: {' '.join(cmd)}")
        print(f"❌ Error: {e.stderr}")
        raise


def get_latest_date_from_existing_data():
    """Get the latest date from existing data to use as a starting point."""
    if not CSV_OUT.exists():
        return None

    try:
        existing_df = pd.read_csv(CSV_OUT)
        if existing_df.empty:
            return None

        latest_date = pd.to_datetime(existing_df["started_at"]).max()
        print(f"ℹ️  Latest existing data from: {latest_date.strftime('%Y-%m-%dT%H:%M:%SZ')}")
        return latest_date.strftime("%Y-%m-%dT%H:%M:%SZ")
    except (pd.errors.EmptyDataError, pd.errors.ParserError, KeyError, ValueError) as e:
        print(f"⚠️  Could not determine latest date from existing data: {e}")
        return None


def fetch_workflow_runs(since_date=None):
    """Fetch workflow run IDs since the given date from the main branch only."""
    if since_date:
        print(f"ℹ️  Fetching runs from main branch since: {since_date}")
        args = [
            "api", "--paginate",
            "--jq", f".workflow_runs[] | select(.created_at > \"{since_date}\" and .head_branch == \"main\") | .id",
            f"repos/{REPO}/actions/runs"
        ]
    else:
        print("ℹ️  Fetching all workflow runs from main branch...")
        args = [
            "api", "--paginate",
            "--jq", ".workflow_runs[] | select(.head_branch == \"main\") | .id",
            f"repos/{REPO}/actions/runs"
        ]
    
    output = run_gh_command(args)
    if not output:
        print("ℹ️  No workflow runs found")
        return []
    
    run_ids = [line.strip() for line in output.split('\n') if line.strip()]
    print(f"ℹ️  Found {len(run_ids)} runs to process")
    return run_ids


def fetch_all_job_data(run_ids):
    """Fetch all job data for multiple runs in batches."""
    if not run_ids:
        return []
    
    print(f"ℹ️  Fetching job data for {len(run_ids)} runs...")
    
    all_jobs = []
    batch_size = 10
    
    for i in range(0, len(run_ids), batch_size):
        batch = run_ids[i:i + batch_size]
        print(f"ℹ️  Processing batch {i//batch_size + 1}/{(len(run_ids) + batch_size - 1)//batch_size}")
        
        for run_id in batch:
            try:
                args = [
                    "api",
                    f"repos/{REPO}/actions/runs/{run_id}/jobs"
                ]
                
                output = run_gh_command(args)
                if output:
                    try:
                        job_data = json.loads(output)
                        jobs = job_data.get('jobs', [])
                        for job in jobs:
                            job['run_id'] = run_id
                        all_jobs.extend(jobs)
                    except json.JSONDecodeError as e:
                        print(f"⚠️  Could not parse job JSON for run {run_id}: {e}")
                                
            except subprocess.CalledProcessError:
                print(f"ℹ️  No jobs found for run {run_id}")
                continue
    
    print(f"ℹ️  Fetched {len(all_jobs)} jobs")
    return all_jobs


def process_job_data(job_data_list):
    """Process the raw job data to extract our target step information."""
    matching_steps = []
    
    for job_data in job_data_list:
        run_id = job_data.get('run_id')
        job_name = job_data.get('name', '')
        steps = job_data.get('steps', [])
        
        if "(build)" in job_name.lower() or "(new release)" in job_name.lower():
            continue
        
        for step in steps:
            if (step.get('name') == STEP_NAME and 
                step.get('status') == 'completed' and 
                step.get('conclusion') == 'success'):
                
                matching_steps.append({
                    'run_id': run_id,
                    'job': job_name,
                    'name': step['name'],
                    'started_at': step['started_at'],
                    'completed_at': step['completed_at']
                })
    
    print(f"ℹ️  Found {len(matching_steps)} matching steps")
    return matching_steps


def fetch_new_data():
    """Fetch new data using GitHub CLI with incremental updates."""
    print("ℹ️  Fetching new data from GitHub Actions...")
    
    since_date = get_latest_date_from_existing_data()
    run_ids = fetch_workflow_runs(since_date)
    
    if not run_ids:
        return ""
    
    job_data_list = fetch_all_job_data(run_ids)
    
    if not job_data_list:
        print("ℹ️  No job data found")
        return ""
    
    matching_steps = process_job_data(job_data_list)
    
    if not matching_steps:
        print("ℹ️  No matching job steps found")
        return ""
    
    jsonl_lines = [json.dumps(step) for step in matching_steps]
    result = '\n'.join(jsonl_lines)
    
    print(f"ℹ️  Found {len(matching_steps)} successful job steps")
    return result


def load_existing_data():
    """Load existing data if it exists."""
    if CSV_OUT.exists():
        print(f"ℹ️  Loading existing data from {CSV_OUT}")
        existing_df = pd.read_csv(CSV_OUT)
        existing_df["started"] = pd.to_datetime(existing_df["started_at"])
        existing_df["completed"] = pd.to_datetime(existing_df["completed_at"])
        return existing_df
    else:
        print("ℹ️  No existing data found, starting fresh")
        return pd.DataFrame()


def process_new_data(raw_data):
    """Process raw JSONL data into a DataFrame."""
    if not raw_data:
        print("ℹ️  No new data to process")
        return pd.DataFrame()
    
    df = pd.read_json(StringIO(raw_data), lines=True)

    if df.empty:
        print("ℹ️  No new data to process")
        return df

    df["started"] = pd.to_datetime(df["started_at"])
    df["completed"] = pd.to_datetime(df["completed_at"])
    df["duration_m"] = ((df["completed"] - df["started"])
                        .dt.total_seconds() / 60)
    df['variant'] = df['job'].str.findall(r'\(([^()]+)\)').str[-1]
    df[['os', 'python_version', 'psychopy_version']] = df['variant'].str.split(',', expand=True)
    df['os'] = df['os'].str.strip()
    df['python_version'] = df['python_version'].str.strip()
    df['psychopy_version'] = df['psychopy_version'].str.strip()

    print(f"ℹ️  Processed {len(df)} new data points")
    return df


def merge_and_deduplicate(existing_df, new_df):
    """Merge existing and new data, removing duplicates."""
    if new_df.empty:
        return existing_df, 0

    if existing_df.empty:
        return new_df.sort_values("started"), len(new_df)

    # Create a set of existing records for fast lookup
    existing_keys = set(
        zip(existing_df['run_id'], existing_df['job'], existing_df['started_at'])
    )
    
    # Filter new data to only include records not in existing data
    new_mask = ~new_df.apply(
        lambda row: (row['run_id'], row['job'], row['started_at']) in existing_keys,
        axis=1
    )
    
    truly_new_df = new_df[new_mask]
    duplicates_removed = len(new_df) - len(truly_new_df)
    
    if duplicates_removed > 0:
        print(f"ℹ️  Removed {duplicates_removed} duplicate entries from new data")
    
    if truly_new_df.empty:
        print("ℹ️  All fetched data were duplicates - no new records to add")
        return existing_df, 0

    # Combine existing data with truly new data
    combined_df = pd.concat([existing_df, truly_new_df], ignore_index=True)
    combined_df = combined_df.sort_values("started").reset_index(drop=True)
    
    actual_new_records = len(truly_new_df)
    return combined_df, actual_new_records


def save_data(df, raw_new_data, actual_new_count):
    """Save the processed data to files."""
    if df.empty:
        print("ℹ️  No data to save")
        return

    if actual_new_count > 0:
        df.to_csv(CSV_OUT, index=False)
        print(f"✅ Wrote {len(df)} records to {CSV_OUT}")

        if raw_new_data:
            mode = 'a' if JSON_CACHE.exists() else 'w'
            with open(JSON_CACHE, mode, encoding='utf-8') as f:
                if mode == 'a':
                    f.write('\n')
                f.write(raw_new_data)
            print(f"✅ Appended new raw data to {JSON_CACHE}")
    else:
        print("ℹ️  No files updated (no new data to save)")


def main():
    """Main update process."""
    print("🚀 Starting performance data update...")

    existing_df = load_existing_data()
    raw_new_data = fetch_new_data()
    new_df = process_new_data(raw_new_data)

    if new_df.empty:
        print("✅ Update complete! No new data found.")
        sys.exit(1)

    final_df, actual_new_count = merge_and_deduplicate(existing_df, new_df)

    if actual_new_count <= 0:
        print("✅ Update complete! No new records added (all data were duplicates).")
        sys.exit(1)

    save_data(final_df, raw_new_data, actual_new_count)

    total_count = len(final_df)
    print(f"✅ Update complete! Total records: {total_count} "
          f"(+{actual_new_count} new)")
    sys.exit(0)


if __name__ == "__main__":
    main()