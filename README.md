# YU N-Paraxial Surface App

MATLAB educational ray-tracing tools for **first-order meridional paraxial optics**.

The repository is built around a prescription-driven `y-u` model for optical systems in the `y-z` meridional plane. It is intended for learning and debugging Gaussian optics, ABCD matrix propagation, stops and pupils, paraxial surface refraction, relay systems, telecentric systems, and simple grating-source launch conditions.

Current public-facing state: **Milestone 2.6.3+**.

## Recommended entry points

### V2 lightweight system viewer

Use V2 for normal exploration:

```matlab
addpath(genpath(pwd))
app = YU_NParaxialSurface_App_V2;
```

V2 is intentionally compact and has five tabs:

1. **Ray Diagram**
2. **System Matrix**
3. **Cardinal/Gaussian**
4. **Stop/Pupils**
5. **Equations**

V2 focuses on fast first-order layout exploration. It does not run the heavier paraxial-validity or field-sweep diagnostic tools.

## Optical model

Forward propagation is along increasing `z`. The ray state is

```text
r = [y; u]
```

where `y` is ray height and `u` is the paraxial ray angle in radians. In the main trace engine, `u` is used directly as the first-order angle/slope coordinate. The app does not reinterpret `u` as `atan(u)` in the main trace.

Core matrices:

```text
Translation over d:
T(d) = [1 d; 0 1]

Thin lens:
L(f) = [1 0; -1/f 1]

Paraxial spherical refracting surface, n1 -> n2:
S(n1,n2,R) = [1 0; (n1-n2)/(n2*R) n1/n2]
```

Stop and dummy elements use the identity matrix. Aperture clipping is evaluated at the element vertex plane before applying the element matrix.

Surface-radius convention:

```text
R > 0   center of curvature is to the right, at larger z
R < 0   center of curvature is to the left, at smaller z
R = Inf plane refracting surface
```

This is a first-order paraxial model. It is not a full exact Snell ray tracer, not a 3D skew-ray tracer, and not an aberration optimizer.

## Prescription table

Optical systems are defined by a table. The canonical columns are:

| Column | Meaning |
|---|---|
| `element_id` | Element label, for example `L1`, `STOP1`, `S1` |
| `event_order` | Ordering key for same-plane events |
| `type` | `thinlens`, `surface`, `stop`, or `dummy` |
| `z` | Axial event location in mm |
| `aperture_radius` | Clear semi-aperture in mm; `Inf` means no clipping |
| `focal_length` | Thin-lens focal length in mm; used only by `thinlens` |
| `radius_R` | Surface radius in mm; used only by `surface` |
| `n_before` | Refractive index before the event |
| `n_after` | Refractive index after the event |
| `enabled` | Logical flag |

Enabled elements are sorted by increasing `z`, then increasing `event_order`, then stable table row order.

CSV and MAT prescription load/save are available in V2 through the File menu. MAT save writes the variable `prescription`.

## Built-in classical use-case library

Milestone 2.6.3 introduced a structured default case library:

```matlab
cases = nparaxial_default_case_library_yu();
caseDef = nparaxial_get_default_case_yu("basic_single_lens_m_minus_0p5");
```

Each case carries metadata such as:

```text
name
key
family
description
object_conjugate
object_z
launch_z
prescription
field settings
ray fan settings
source mode
expected behavior
teaching point
```

The V2 default case is:

```text
Basic - Single lens finite conjugate, m=-0.5
```

### Case families

The current default library includes:

| Family | Cases |
|---|---|
| Basic | Single lens finite conjugate `m=-0.5`; single lens `1:1`; single lens collimator; single focusing lens with object at infinity |
| Relay | 4f relay `1:1`; 4f reducer `m=-0.5`; 4f magnifier `m=-2` |
| Afocal | Keplerian telescope; Galilean telescope |
| Telecentric | Object-space telecentric `1:1`; image-space telecentric `1:1`; doubly telecentric 4f relay `m=-0.25` |
| Thick | Biconvex thick lens; plano-convex thick lens; meniscus thick lens |
| Debug | Legacy two-thin-lens; stop clipping demo; homogeneous translation |

For finite-conjugate cases, the object metadata is normally

```text
object_z = 0
launch_z = 0
```

For infinity-conjugate cases, the library uses

```text
object_z = Inf
launch_z = finite value
```

`object_z = Inf` is metadata only. The low-level trace engine still receives finite launch coordinates. Collimated object-at-infinity rays are generated with `nparaxial_make_collimated_rays_yu`.

## Ray-source modes

The current app supports several educational source/ray-launch modes:

| Mode | Purpose |
|---|---|
| Point object / manual fixed-angle fan | Launches a symmetric paraxial angle fan from the object plane |
| Aperture-limited admitted cone | Samples launch angles from the first-order aperture/vignetting interval |
| Collimated source | Finite launch-plane representation of an object at infinity |
| Grating object | Generates paraxial diffraction-order launch rays from the grating equation |

The grating object is a source/ray-generator condition. It is not inserted as an ABCD optical element.

For grating order `m`, the launch direction is based on

```text
n_out sin(theta_m) = n_in sin(theta_i) + m lambda / period
```

Only propagating orders are traced. Non-propagating orders are reported but not launched.

## System diagnostics

The apps compute and display first-order diagnostics, including:

- system ABCD matrix,
- chronological matrix chain,
- finite image-plane solve,
- magnification estimate,
- cardinal and Gaussian points,
- focal-length overlays,
- aperture stop,
- entrance and exit pupils,
- chief and marginal rays,
- ray blocking/vignetting status,
- first-order equations used by the selected model.

For a system matrix

```text
[y2; u2] = [A B; C D] [y1; u1]
```

finite image location is solved using

```text
B_total = B + x*D = 0
x = -B/D
z_img = z_ref + x
```

For finite-power systems, the cardinal helper reports the usual first-order focal, principal, and nodal point positions. For afocal or zero-power systems, finite focal/principal points are not forced.

## Plotting and UI notes

Recent V2 plotting/UI changes include:

- role-based ray styling,
- de-duplicated legends,
- compact/detailed/off element labels,
- stable cleanup of old ray and overlay graphics,
- system focal-length overlay,
- cardinal point overlays,
- field-height tracing,
- grating order colors with a centered diverging scheme,
- File-menu prescription load/save.

V2 keeps a single global **Run Trace** button. Prescription load/save is available from the File menu.

## Repository layout

Important folders and files:

```text
YU_NParaxialSurface_App_V2.m          lightweight system viewer
core/                                 paraxial model, case library, tracing, diagnostics
plotting/                             plot helpers and visual styles
workflows/                            scriptable trace/validity/field-sweep workflows
examples/                             small launch/demo scripts
tests/                                milestone smoke and regression demos
```

Important case-library helpers:

```text
core/nparaxial_default_case_library_yu.m
core/nparaxial_get_default_case_yu.m
core/nparaxial_default_prescription_yu.m
core/nparaxial_make_collimated_rays_yu.m
```

## Scriptable workflows

The app logic is also available through scriptable workflows under `workflows/`, including trace, validity, and field-sweep workflows. V2 uses the lightweight trace path; heavier diagnostics remain available through workflow scripts.

Typical pattern:

```matlab
addpath(genpath(pwd))
caseDef = nparaxial_get_default_case_yu("relay_4f_1to1");
prescription = caseDef.prescription;
```

## Tests

Run the full milestone demo runner from the repository root:

```matlab
addpath(genpath(pwd))
run_nparaxial_milestone_demos_yu
```

Useful focused checks:

```matlab
demo_nparaxial_milestone260_lightweight_v2_yu
demo_nparaxial_milestone2621_v2_field_controls_plotting_yu
demo_nparaxial_milestone263_classical_default_cases_yu
```

The tests check representative Gaussian expected values, V2 five-tab structure, classical default case loading, infinity-object finite launch handling, grating/point tracing, and compatibility with earlier default prescriptions.

## Current limitations

- Meridional `y-z` model only.
- First-order paraxial propagation only.
- No 3D skew rays.
- No exact Snell propagation through real curved surfaces.
- No Seidel/Zernike aberration model.
- No wave-optics propagation.
- The grating model is a paraxial source generator, not a physical diffractive optical element inside the ABCD chain.

These limitations are deliberate. The repository is currently a staged learning and prototyping environment for Gaussian optics and prescription-driven first-order ray tracing.

## Development direction

The near-term development path is:

```text
2D paraxial thin lens
2D paraxial thick lens / vertex-plane surfaces
2D exact Snell ray trace
3D paraxial thin/thick lens models
3D exact Snell ray trace
aberration diagnostics and Zernike/Seidel links
wave-optics / ASM studies
```

The current stable emphasis is the first two stages: clean 2D paraxial thin-lens and vertex-plane surface modeling with structured classical examples.
