#!/usr/bin/env python3
"""Generate performance plots from the collected data."""
import subprocess
import json
from matplotlib.lines import Line2D
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np

from config import SCRIPT_DIR, CSV_FILE, PLOTS_DIR, REPO


def run_gh_command(args):
    """Run a GitHub CLI command and return the output."""
    try:
        result = subprocess.run(
            ["gh"] + args, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
            text=True, check=True
        )
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        print(f"⚠️  Error running gh command: {e.stderr}")
        return None


def fetch_releases():
    """Fetch GitHub releases for the repository."""
    print("ℹ️  Fetching GitHub releases...")
    
    args = [
        "api", "--paginate",
        "--jq", ".[] | {tag_name: .tag_name, published_at: .published_at, name: .name}",
        f"repos/{REPO}/releases"
    ]
    
    output = run_gh_command(args)
    if not output:
        return []
    
    releases = []
    for line in output.split('\n'):
        if line.strip():
            try:
                releases.append(json.loads(line.strip()))
            except json.JSONDecodeError as e:
                print(f"⚠️  Could not parse release JSON: {e}")
    
    print(f"ℹ️  Found {len(releases)} releases")
    return releases


def smart_run_ticks(total_runs, run_ids, max_ticks=20):
    """Generate smart run ID ticks that adapt to the data range."""
    if total_runs <= 10:
        tick_step = 1
    elif total_runs <= 50:
        tick_step = max(1, total_runs // 10)
    else:
        tick_step = max(1, total_runs // max_ticks)
    
    tick_indices = [i for i in range(0, total_runs, tick_step) if i < total_runs]
    
    if tick_indices and (total_runs - 1 - tick_indices[-1]) > tick_step // 2:
        tick_indices.append(total_runs - 1)
    
    # Use simplified run_id labels (just the last few digits to keep it readable)
    tick_labels = []
    for i in tick_indices:
        if i < len(run_ids):
            run_id_str = str(run_ids[i])
            # Use last 4 digits for readability
            simplified_id = run_id_str[-4:] if len(run_id_str) > 4 else run_id_str
            tick_labels.append(simplified_id)
    
    return tick_indices, tick_labels


def optimize_release_labels(release_markers, total_runs):
    """Optimize release label positioning to avoid overlaps."""
    if not release_markers:
        return []
    
    releases_with_pos = [
        {'x_pos': r['run_index'], 'tag': r['tag'], 'date': r['date']}
        for r in release_markers
    ]
    releases_with_pos.sort(key=lambda x: x['x_pos'])
    
    heights = [0.95, 0.90, 0.85, 0.80]
    min_distance = max(1, total_runs // 20)  # Adapt minimum distance based on total runs
    optimized_releases = []
    last_x = -min_distance
    height_idx = 0
    
    for release in releases_with_pos:
        if release['x_pos'] - last_x < min_distance:
            height_idx = (height_idx + 1) % len(heights)
        else:
            height_idx = 0
        
        optimized_releases.append({
            **release,
            'height': heights[height_idx]
        })
        last_x = release['x_pos']
    
    return optimized_releases


def prepare_release_markers(releases, run_dates_mapping):
    """Prepare release markers for plotting by finding closest run indices to release dates.
    Only includes releases that occur on or after the first run date."""
    if not releases or not run_dates_mapping:
        return []
    
    # Get the first run date to filter out earlier releases
    first_run_date = min(run_dates_mapping.values())
    if hasattr(first_run_date, 'tz') and first_run_date.tz is not None:
        first_run_date_naive = first_run_date.tz_convert('UTC').tz_localize(None)
    else:
        first_run_date_naive = first_run_date
    
    release_markers = []
    for release in releases:
        try:
            release_date = pd.to_datetime(release['published_at'])
            # Ensure release_date is timezone-naive for comparison
            if release_date.tz is not None:
                release_date = release_date.tz_convert('UTC').tz_localize(None)
            
            # Skip releases that are before the first run date
            if release_date < first_run_date_naive:
                continue
            
            # Find the run closest to this release date
            closest_run_index = None
            min_time_diff = float('inf')
            
            for run_index, run_date in run_dates_mapping.items():
                # Ensure run_date is timezone-naive for comparison
                if hasattr(run_date, 'tz') and run_date.tz is not None:
                    run_date_naive = run_date.tz_convert('UTC').tz_localize(None)
                else:
                    run_date_naive = run_date
                
                time_diff = abs((release_date - run_date_naive).total_seconds())
                if time_diff < min_time_diff:
                    min_time_diff = time_diff
                    closest_run_index = run_index
            
            # Only include if the release is within a reasonable time range (30 days)
            if closest_run_index is not None and min_time_diff <= 30 * 24 * 3600:  # 30 days in seconds
                closest_run_date = run_dates_mapping[closest_run_index]
                if hasattr(closest_run_date, 'date'):
                    closest_run_date_formatted = closest_run_date.date()
                else:
                    closest_run_date_formatted = closest_run_date
                
                release_markers.append({
                    'run_index': closest_run_index,
                    'tag': release['tag_name'],
                    'name': release.get('name', release['tag_name']),
                    'date': release_date.date(),
                    'closest_run_date': closest_run_date_formatted
                })
        except (ValueError, KeyError) as e:
            print(f"⚠️  Could not parse release date for {release.get('tag_name', 'unknown')}: {e}")
    
    return sorted(release_markers, key=lambda x: x['run_index'])


def sanitize_filename(name):
    """Sanitize names for use as filenames."""
    return name.replace("/", "_").replace(", ", "_").replace(" ", "_")


def load_data():
    """Load the performance data."""
    if not CSV_FILE.exists():
        print(f"❌ No data file found at {CSV_FILE}")
        return None

    # Read CSV with python_version as string to preserve "3.10"
    df = pd.read_csv(CSV_FILE, dtype={'python_version': str})
    df["started"] = pd.to_datetime(df["started_at"])
    df["completed"] = pd.to_datetime(df["completed_at"])
    df = df.sort_values("started")

    print(f"ℹ️  Loaded {len(df)} records from {CSV_FILE}")
    print(f"ℹ️  Data spans {df['started'].dt.date.nunique()} distinct dates")
    return df


def calculate_run_average(df):
    """Calculate average for each run_id."""
    if df.empty:
        return pd.DataFrame()
    
    return df.groupby('run_id').agg({
        'duration_m': 'mean',
        'started': 'first'  # Keep the first start time for each run_id
    }).reset_index()


def calculate_trend_line(x_data, y_data):
    """Calculate linear trend line using least squares regression."""
    if len(x_data) < 2:
        return [], []
    
    valid_mask = ~(np.isnan(x_data) | np.isnan(y_data))
    x_clean, y_clean = np.array(x_data)[valid_mask], np.array(y_data)[valid_mask]
    
    if len(x_clean) < 2:
        return [], []
    
    coeffs = np.polyfit(x_clean, y_clean, 1)
    x_trend = np.linspace(x_clean.min(), x_clean.max(), 100)
    y_trend = np.polyval(coeffs, x_trend)
    
    return x_trend, y_trend


def setup_plot_data(df_data):
    """Setup common plot data: run_ids, run mapping, and scatter positions."""
    # Get unique run_ids in chronological order
    unique_runs = df_data.groupby('run_id')['started'].first().sort_values()
    run_ids = unique_runs.index.tolist()
    run_to_idx = {run_id: i for i, run_id in enumerate(run_ids)}
    
    # Create mapping of run index to date for release markers
    run_dates_mapping = {i: date for i, date in enumerate(unique_runs.values)}
    
    # Calculate scatter positions with slight offsets for multiple variants per run
    all_run_ids = df_data['run_id'].tolist()
    run_counts = {run_id: all_run_ids.count(run_id) for run_id in run_ids}
    
    x_positions = []
    run_counters = {run_id: 0 for run_id in run_ids}
    
    for run_id in all_run_ids:
        run_idx = run_to_idx[run_id]
        count = run_counts[run_id]
        current = run_counters[run_id]
        
        if count == 1:
            offset = 0
        else:
            # Spread variants around the run position
            offsets = np.linspace(-0.3, 0.3, count)
            offset = offsets[current]
        
        x_positions.append(run_idx + offset)
        run_counters[run_id] += 1
    
    return run_ids, run_to_idx, run_dates_mapping, x_positions


def add_run_average_line(ax, df_variant, run_to_idx):
    """Add run average and trend lines to a plot."""
    if df_variant.empty:
        return
    
    run_avg = calculate_run_average(df_variant)
    if run_avg.empty:
        return
    
    ra_x, ra_y = [], []
    for _, row in run_avg.iterrows():
        run_id = row['run_id']
        if run_id in run_to_idx:
            ra_x.append(run_to_idx[run_id])
            ra_y.append(row['duration_m'])
    
    if ra_x and ra_y:
        ax.plot(ra_x, ra_y, color='blue', linewidth=2, alpha=0.8, 
               label='Run Average', zorder=4)
        
        if len(ra_x) >= 2:
            trend_x, trend_y = calculate_trend_line(ra_x, ra_y)
            if len(trend_x) > 0:
                ax.plot(trend_x, trend_y, color='green', linewidth=2, 
                       linestyle='--', alpha=0.8, label='Trend Line', zorder=4)



def add_release_markers(ax, release_markers, font_size=8):
    """Add release markers to a plot."""
    optimized_releases = optimize_release_labels(release_markers, len(release_markers))
    for release in optimized_releases:
        ax.axvline(x=release['x_pos'], color='red', linestyle='--', alpha=0.7, zorder=2)
        ax.text(release['x_pos'], ax.get_ylim()[1] * release['height'], 
               f"{release['tag']}\n({release['date']})", 
               rotation=90, ha='right', va='top', fontsize=font_size, 
               color='red', alpha=0.8)


def setup_axis_formatting(ax, run_ids, title, max_ticks=20):
    """Setup common axis formatting for plots."""
    ax.set_title(title)
    ax.set_xlabel("Run ID")
    ax.set_ylabel("Duration (minutes)")
    
    tick_indices, tick_labels = smart_run_ticks(len(run_ids), run_ids, max_ticks)
    ax.set_xticks(tick_indices)
    ax.set_xticklabels(tick_labels, rotation=45, ha="right")
    ax.grid(True, linestyle="--", linewidth=0.5, alpha=0.7, zorder=1)


def create_variant_plots(df, releases):
    """Create plots grouped by OS with subplots for each Python/PsychoPy version."""
    print("ℹ️  Creating per-OS plots with subplots...")

    for os_name, os_group in df.groupby("os"):
        variants_in_os = os_group["variant"].unique()
        n_variants = len(variants_in_os)
        
        if n_variants == 0:
            continue
            
        n_cols = min(3, n_variants)
        n_rows = (n_variants + n_cols - 1) // n_cols
        
        fig, axes = plt.subplots(n_rows, n_cols, figsize=(5*n_cols, 4*n_rows))
        fig.suptitle(f"Installation Duration: {os_name}", fontsize=16, y=0.98)
        
        if n_variants == 1:
            axes = [axes]
        elif n_rows == 1:
            axes = list(axes) if n_variants > 1 else [axes]
        else:
            axes = axes.flatten()
        
        for idx, variant in enumerate(variants_in_os):
            ax = axes[idx]
            grp = os_group[os_group["variant"] == variant].copy()
            grp = grp.sort_values("started").reset_index(drop=True)
            
            if grp.empty:
                ax.set_visible(False)
                continue
            
            run_ids, run_to_idx, run_dates_mapping, x_positions = setup_plot_data(grp)
            release_markers = prepare_release_markers(releases, run_dates_mapping)

            ax.scatter(x_positions, grp["duration_m"].values, marker="o", alpha=0.7, 
                      s=30, zorder=3, label='Individual Runs')
            
            add_run_average_line(ax, grp, run_to_idx)
            
            python_ver = grp["python_version"].iloc[0] if len(grp) > 0 else "Unknown"
            psychopy_ver = grp["psychopy_version"].iloc[0] if len(grp) > 0 else "Unknown"
            title = f"Python {python_ver}, PsychoPy {psychopy_ver}"
            setup_axis_formatting(ax, run_ids, title, max_ticks=10)
            
            add_release_markers(ax, release_markers, font_size=7)
            
            if idx == 0:
                ax.legend(loc='upper left', framealpha=0.9, fontsize=9)
        
        for idx in range(n_variants, len(axes)):
            axes[idx].set_visible(False)
        
        plt.tight_layout()
        
        path = PLOTS_DIR / f"{sanitize_filename(os_name)}_subplots.png"
        fig.savefig(path, dpi=150, bbox_inches='tight')
        plt.close(fig)

        print(f"✅ OS '{os_name}': {n_variants} variants → {path}")


def create_combined_plot(df, releases):
    """Create a combined plot with all runs."""
    print("ℹ️  Creating combined plot...")

    df_all = df.sort_values("started").reset_index(drop=True)
    run_ids, run_to_idx, run_dates_mapping, x_all = setup_plot_data(df_all)
    
    release_markers = prepare_release_markers(releases, run_dates_mapping)

    fig, ax = plt.subplots(figsize=(16, 9))
    
    variants = df_all["variant"].unique()
    colors = plt.colormaps['tab10'](np.linspace(0, 1, len(variants)))
    
    for i, variant in enumerate(variants):
        mask = df_all["variant"] == variant
        x_variant = [x_all[j] for j in range(len(x_all)) if mask.iloc[j]]
        y_variant = [df_all["duration_m"].values[j] for j in range(len(x_all)) if mask.iloc[j]]
        ax.scatter(x_variant, y_variant, alpha=0.7, label=variant,
                   color=colors[i], s=30, zorder=3)

    add_run_average_line(ax, df_all, run_to_idx)
    
    setup_axis_formatting(ax, run_ids, 
                         "All Runs: Setup Environment and Install (with GitHub Releases)", 
                         max_ticks=25)
    
    add_release_markers(ax, release_markers)

    handles, labels = ax.get_legend_handles_labels()
    if release_markers:
        release_line = Line2D([0], [0], color='red', linestyle='--', alpha=0.7)
        handles.append(release_line)
        labels.append('GitHub Releases')
    
    if len(handles) > 8:
        ax.legend(handles, labels, bbox_to_anchor=(1.05, 1), loc='upper left', framealpha=0.9)
    else:
        ax.legend(handles, labels, loc='upper left', framealpha=0.9)
    
    fig.tight_layout()

    combined_path = PLOTS_DIR / "all_runs.png"
    fig.savefig(combined_path, dpi=150, bbox_inches='tight')
    plt.close(fig)

    total_runs = len(df_all)
    span_runs = len(run_ids)
    releases_in_range = len(release_markers)
    print(f"✅ Combined plot: {total_runs} runs over {span_runs} unique run IDs, "
          f"{releases_in_range} releases → {combined_path}")


def create_averages_comparison_plot(df, releases):
    """Create subplots showing aggregated run averages by Python, PsychoPy, and OS categories."""
    print("ℹ️  Creating averages comparison plot with subplots...")

    df_all = df.sort_values("started").reset_index(drop=True)
    run_ids, run_to_idx, run_dates_mapping, _ = setup_plot_data(df_all)
    
    if not run_ids:
        print("⚠️  No data for averages comparison plot")
        return

    release_markers = prepare_release_markers(releases, run_dates_mapping)

    # Create figure with 3 subplots (1 row, 3 columns)
    fig, axes = plt.subplots(1, 3, figsize=(24, 8))
    
    # Define the three category types
    subplot_configs = [
        {
            'ax': axes[0],
            'title': 'Python Versions',
            'categories': [(f'Python {py_ver}', df[df['python_version'] == py_ver]) 
                          for py_ver in sorted(df['python_version'].unique())],
            'color_map': 'tab10'
        },
        {
            'ax': axes[1], 
            'title': 'PsychoPy Versions',
            'categories': [(f'PsychoPy {psychopy_ver}', df[df['psychopy_version'] == psychopy_ver])
                          for psychopy_ver in sorted(df['psychopy_version'].unique())],
            'color_map': 'Set1'
        },
        {
            'ax': axes[2],
            'title': 'Operating Systems', 
            'categories': [(f'{os_name}', df[df['os'] == os_name])
                          for os_name in sorted(df['os'].unique())],
            'color_map': 'Set2'
        }
    ]
    
    # Plot each subplot
    for subplot_config in subplot_configs:
        ax = subplot_config['ax']
        categories = subplot_config['categories']
        color_map = plt.colormaps[subplot_config['color_map']]
        
        # Add "All Runs" line to each subplot
        run_avg_all = calculate_run_average(df_all)
        if not run_avg_all.empty:
            ra_x_all, ra_y_all = [], []
            for _, row in run_avg_all.iterrows():
                run_id = row['run_id']
                if run_id in run_to_idx:
                    ra_x_all.append(run_to_idx[run_id])
                    ra_y_all.append(row['duration_m'])
            
            if ra_x_all and ra_y_all:
                ax.plot(ra_x_all, ra_y_all, color='black', linewidth=3, alpha=0.8, 
                       label='All Runs', zorder=5)
        
        # Add category-specific lines
        for i, (label, data) in enumerate(categories):
            if data.empty:
                continue
                
            color = color_map(i / max(1, len(categories) - 1))
            
            run_avg = calculate_run_average(data)
            if run_avg.empty:
                continue
            
            ra_x, ra_y = [], []
            for _, row in run_avg.iterrows():
                run_id = row['run_id']
                if run_id in run_to_idx:
                    ra_x.append(run_to_idx[run_id])
                    ra_y.append(row['duration_m'])
            
            if ra_x and ra_y:
                ax.plot(ra_x, ra_y, color=color, linewidth=2, alpha=0.8, 
                       label=label, zorder=4)

        # Format the subplot
        setup_axis_formatting(ax, run_ids, 
                             f"Installation Duration: {subplot_config['title']}", 
                             max_ticks=15)
        
        # Add release markers
        add_release_markers(ax, release_markers, font_size=6)
        
        # Add legend
        handles, labels = ax.get_legend_handles_labels()
        if release_markers and subplot_config['title'] == 'Python Versions':  # Only add to first subplot
            release_line = Line2D([0], [0], color='red', linestyle='--', alpha=0.7)
            handles.append(release_line)
            labels.append('GitHub Releases')
        
        # Sort legend so "All Runs" comes first
        sorted_items = sorted(zip(handles, labels), key=lambda x: (x[1] != 'All Runs', x[1]))
        handles, labels = zip(*sorted_items)
        
        ax.legend(handles, labels, loc='upper left', framealpha=0.9, fontsize=9)
    
    fig.tight_layout()

    averages_path = PLOTS_DIR / "averages_comparison.png"
    fig.savefig(averages_path, dpi=150, bbox_inches='tight')
    plt.close(fig)

    print(f"✅ Averages comparison plot with subplots → {averages_path}")


def generate_readme(created_plots, df):
    """Generate README.md with the created plots and statistics."""
    print("ℹ️  Generating README.md...")
    
    readme_content = "# Performance Data\n\n"
    
    # Add summary statistics section
    readme_content += "## Summary Statistics\n\n"
    
    total_runs = len(df)
    unique_run_ids = df['run_id'].nunique()
    date_min = df['started'].min().date()
    date_max = df['started'].max().date()
    distinct_dates = df['started'].dt.date.nunique()
    
    readme_content += f"- **Total test runs**: {total_runs}\n"
    readme_content += f"- **Unique workflow runs**: {unique_run_ids}\n"
    readme_content += f"- **Date range**: {date_min} to {date_max}\n"
    readme_content += f"- **Distinct test dates**: {distinct_dates}\n\n"
    
    # Duration statistics
    readme_content += "### Installation Duration\n\n"
    readme_content += f"- **Average**: {df['duration_m'].mean():.2f} minutes\n"
    readme_content += f"- **Median**: {df['duration_m'].median():.2f} minutes\n"
    readme_content += f"- **Min**: {df['duration_m'].min():.2f} minutes\n"
    readme_content += f"- **Max**: {df['duration_m'].max():.2f} minutes\n"
    readme_content += f"- **Std Dev**: {df['duration_m'].std():.2f} minutes\n\n"
    
    # By Operating System
    readme_content += "### By Operating System\n\n"
    os_stats = df.groupby('os').agg({
        'duration_m': ['count', 'mean', 'median']
    }).round(2)
    os_stats.columns = ['Count', 'Avg (min)', 'Median (min)']
    
    readme_content += "| OS | Test Runs | Avg Duration | Median Duration |\n"
    readme_content += "|---|---:|---:|---:|\n"
    for os_name, row in os_stats.iterrows():
        readme_content += f"| {os_name} | {int(row['Count'])} | {row['Avg (min)']:.2f} min | {row['Median (min)']:.2f} min |\n"
    readme_content += "\n"
    
    # By Python Version
    readme_content += "### By Python Version\n\n"
    py_stats = df.groupby('python_version').agg({
        'duration_m': ['count', 'mean', 'median']
    }).round(2)
    py_stats.columns = ['Count', 'Avg (min)', 'Median (min)']
    
    readme_content += "| Python Version | Test Runs | Avg Duration | Median Duration |\n"
    readme_content += "|---|---:|---:|---:|\n"
    for py_ver, row in py_stats.iterrows():
        readme_content += f"| {py_ver} | {int(row['Count'])} | {row['Avg (min)']:.2f} min | {row['Median (min)']:.2f} min |\n"
    readme_content += "\n"
    
    # By PsychoPy Version
    readme_content += "### By PsychoPy Version\n\n"
    psychopy_stats = df.groupby('psychopy_version').agg({
        'duration_m': ['count', 'mean', 'median']
    }).round(2)
    psychopy_stats.columns = ['Count', 'Avg (min)', 'Median (min)']
    
    readme_content += "| PsychoPy Version | Test Runs | Avg Duration | Median Duration |\n"
    readme_content += "|---|---:|---:|---:|\n"
    for psychopy_ver, row in psychopy_stats.iterrows():
        readme_content += f"| {psychopy_ver} | {int(row['Count'])} | {row['Avg (min)']:.2f} min | {row['Median (min)']:.2f} min |\n"
    readme_content += "\n"
    
    # Configuration Performance
    readme_content += "### Configuration Performance\n\n"
    variant_stats = df.groupby('variant').agg({
        'duration_m': ['count', 'mean']
    }).round(2)
    variant_stats.columns = ['Count', 'Avg Duration']
    variant_stats = variant_stats.sort_values('Avg Duration')
    
    readme_content += "**Fastest 5 configurations (by average duration)**:\n\n"
    readme_content += "| Configuration | Test Runs | Avg Duration |\n"
    readme_content += "|---|---:|---:|\n"
    for variant, row in variant_stats.head(5).iterrows():
        readme_content += f"| {variant} | {int(row['Count'])} | {row['Avg Duration']:.2f} min |\n"
    readme_content += "\n"
    
    readme_content += "**Slowest 5 configurations (by average duration)**:\n\n"
    readme_content += "| Configuration | Test Runs | Avg Duration |\n"
    readme_content += "|---|---:|---:|\n"
    for variant, row in variant_stats.tail(5).iterrows():
        readme_content += f"| {variant} | {int(row['Count'])} | {row['Avg Duration']:.2f} min |\n"
    readme_content += "\n"
    
    # Add plots section
    readme_content += "## Visualization\n\n"
    
    for plot_info in created_plots:
        plot_name = plot_info['name']
        plot_path = plot_info['path']
        relative_path = f"duration_plots/{plot_path.name}"
        
        readme_content += f"### {plot_name}\n"
        readme_content += f"![{plot_name}]({relative_path})\n\n"
    
    readme_path = SCRIPT_DIR / "README.md"
    with open(readme_path, 'w', encoding='utf-8') as f:
        f.write(readme_content)
    
    print(f"✅ README.md generated with statistics and {len(created_plots)} plots → {readme_path}")


def main():
    """Main plotting process."""
    print("📊 Starting plot generation...")

    PLOTS_DIR.mkdir(exist_ok=True)

    df = load_data()
    if df is None:
        return

    releases = fetch_releases()

    created_plots = []

    combined_path = PLOTS_DIR / "all_runs.png"
    created_plots.append({
        'name': "All Runs",
        'path': combined_path
    })
    
    averages_path = PLOTS_DIR / "averages_comparison.png"
    created_plots.append({
        'name': "Averages Comparison", 
        'path': averages_path
    })

    for os_name, os_group in df.groupby("os"):
        variants_in_os = os_group["variant"].unique()
        if len(variants_in_os) > 0:
            plot_path = PLOTS_DIR / f"{sanitize_filename(os_name)}_subplots.png"
            created_plots.append({
                'name': f"{os_name} Subplots",
                'path': plot_path
            })
    

    create_variant_plots(df, releases)
    create_combined_plot(df, releases)
    create_averages_comparison_plot(df, releases)

    generate_readme(created_plots, df)

    print("✅ Plot generation complete!")


if __name__ == "__main__":
    main()
