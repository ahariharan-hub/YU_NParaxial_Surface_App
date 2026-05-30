# YU_NParaxialSurface_App_V1

Milestone 1.2 is a conservative first-order, prescription-driven paraxial ray
trace app for meridional rays in the y-z plane.

## Conventions

- Forward propagation is along increasing `z`.
- Ray vector is `r = [y; u]`, with `u = dy/dz`.
- Surface radius convention:
  - `R > 0`: center of curvature is at larger `z` than the surface vertex.
  - `R < 0`: center of curvature is at smaller `z`.
  - `R = Inf`: plane refracting surface.
- Translation over axial distance `d`:

```text
T(d) = [1 d; 0 1]
```

- Thin lens:

```text
L(f) = [1 0; -1/f 1]
```

- Paraxial refracting spherical surface from `n1` to `n2`:

```text
S(n1,n2,R) = [1 0; (n1-n2)/(n2*R) n1/n2]
```

- Stop and dummy elements use the identity matrix.
- Aperture clipping is applied at element planes before the element matrix.
- The first enabled row defines the object-space/input medium.
- Enabled elements are applied by increasing `z`, then increasing `event_order`.
  If both are equal, stable table row order is used.
- Image solve uses `B_total = B + x*D = 0`, so `x = -B/D`.
- This milestone accepts only final real image planes with `z_img >= z_ref`,
  where `z_ref` is the last enabled element plane.

## Element Types

- `thinlens`: requires finite nonzero `focal_length`; must not change medium.
- `surface`: requires `radius_R` nonzero or `Inf`; may change medium.
- `stop`: identity matrix with aperture clipping; must not change medium.
- `dummy`: identity reference plane; must not change medium.

## Presets And Data Handling

The app includes built-in default prescriptions for:

- Single thin lens
- Two thin lenses
- Two-surface thick lens
- Stop clipping demo

The prescription table can be checked before tracing and saved or loaded as
CSV or MAT. The MAT save helper writes a normalized table named
`prescription`. The MAT load helper accepts either a `prescription` variable
or a MAT file containing exactly one table.

After a trace is run, the app can export:

- A ray table CSV with launch, final, and blocking information for every
  sampled ray.
- A text summary containing the system/image summary and matrix table.

The core data helper functions are:

- `prescription_to_table_yu`
- `table_to_prescription_yu`
- `save_prescription_csv_yu`
- `load_prescription_csv_yu`
- `save_prescription_mat_yu`
- `load_prescription_mat_yu`

## Ray Diagram Readability

The upper marginal ray is blue, the chief ray is red, and the lower marginal
ray is green. Blocked rays are drawn with dashed segments and an `x` marker at
the blocking element plane. Element planes are labeled by element ID and type;
thin lenses, refracting surfaces, stops, and dummy planes use distinct line
styles.

## Current Limitations

- Paraxial first-order model only.
- Meridional y-z plane only.
- No exact Snell tracing.
- No aberration calculation.
- No advanced pupil diagnostics.
- No support yet for final image planes before the last enabled element.
