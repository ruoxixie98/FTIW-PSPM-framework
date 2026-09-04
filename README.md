# FTIW-PSPM framework

This repository provides the MATLAB code associated with [Principal
Spatiotemporal Pattern Mapping Detects Brain Activity Partially Decoupled With
Task Timing](https://www.sciencedirect.com/science/article/pii/S1053811926005070).
Principal spatiotemporal pattern mapping (PSPM) quantifies brain activation by
characterizing the dominant task-evoked fMRI signal pattern within a local
functional topography-informed window (FTIW). Without relying on predefined
task-timing-based signal modeling, PSPM can capture task-evoked dynamics shaped
jointly by external stimuli and autonomous cognitive processes, including
activity partially decoupled from explicit task timing.

## Requirements

- MATLAB (tested with R2024a)
- Image Processing Toolbox
- Signal Processing Toolbox
- Parallel Computing Toolbox (optional)

## Inputs

Set the following paths in `main.m`:

| Field | Input |
| --- | --- |
| `cfg.paths.mask_nii` | 3-D analysis mask |
| `cfg.paths.t1_nii` | T1-weighted image |
| `cfg.paths.t2_nii` | T2-weighted image |
| `cfg.paths.rest_nii` | One or more preprocessed resting-state 4-D fMRI runs |
| `cfg.paths.task_nii` | One or more preprocessed task-state 4-D fMRI runs |
| `cfg.paths.task_events` | One events file for each task run, in the same order |
| `cfg.paths.reference_nii` | 3-D NIfTI providing the output header and spatial geometry |
| `cfg.paths.output_dir` | Output directory for the current subject and task |

Before running the framework, the T1- and T2-weighted images must be spatially
registered and resampled to the same space, resolution, and voxel grid as the
functional data. `cfg.paths.reference_nii` defines the spatial metadata of the
output PSPM map. It can be a standard MNI-space brain template, but it must
match the analysis mask and functional images in image dimensions, voxel size,
orientation, and affine transform.

An events file may be either:

- a headerless text file with `onset`, `duration`, and optional `amplitude`
  columns, in seconds; or
- a BIDS `events.tsv` file containing `onset` and `duration`, with optional
  `trial_type` and `amplitude` columns.

Example headerless events file:

```text
0.000   18.000   1
36.000  18.000   1
```

For BIDS files, set `cfg.task.condition` to the required `trial_type`. Leave it
empty to use every event.

Set `cfg.task.name` to a short task label using letters, numbers, underscores,
or hyphens. This label is used in the final output filename.

## Quick start

1. Place the input files in a suitable data directory.
2. Open `main.m` and set the input paths, output directory, task name, TR, and
   other parameters.
3. Run the project from MATLAB:

```matlab
cd('path/to/FTIW-PSPM-framework');
main
```

The framework can also be called from another MATLAB script:

```matlab
outfile = run_ftiw_pspm(cfg);
```

## Output

Files are written to `cfg.paths.output_dir`.

- Main result: `PSPM_<task-name>.nii`
- Event record: `events_used.tsv`
- Optional intermediate files: `Wstruct_*.mat`, `Fdiff_*.mat`,
  `restFeat_*.mat`, and `taskFull_*.mat`

With `cfg.task.name = 'example_task'`, the main result is named:

```text
PSPM_example_task.nii
```

## Citation

If you use this code, please cite:

> Xie, R., Wang, Z., Li, L., Guo, S., Zhang, X., Feng, X., Yang, Z., Liu, Y.,
> Lui, S., Zhao, Y., & Wu, M. (2026). [Principal Spatiotemporal Pattern Mapping
> Detects Brain Activity Partially Decoupled With Task
> Timing](https://doi.org/10.1016/j.neuroimage.2026.122192). *NeuroImage*,
> 122192.
