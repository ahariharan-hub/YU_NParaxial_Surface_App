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
- Cardinal diagnostics as CSV.
- Stop and pupil diagnostics as CSV.
- Chief/marginal ray diagnostics as CSV.
- Invariant and phase-space diagnostics as CSV.
- A combined first-order diagnostics report as TXT.

The core data helper functions are:

- `prescription_to_table_yu`
- `table_to_prescription_yu`
- `save_prescription_csv_yu`
- `load_prescription_csv_yu`
- `save_prescription_mat_yu`
- `load_prescription_mat_yu`
- `nparaxial_export_table_csv_yu`
- `nparaxial_export_summary_txt_yu`
- `nparaxial_combined_report_yu`
- `nparaxial_field_diagnostics_yu`

## Ray Diagram Readability

The upper marginal ray is blue, the chief ray is red, and the lower marginal
ray is green. Blocked rays are drawn with dashed segments and an `x` marker at
the blocking element plane. Element planes are labeled by element ID and type;
thin lenses, refracting surfaces, stops, and dummy planes use distinct line
styles.

## First-Order Diagnostics

Milestone 2 adds first-order system diagnostics without changing the paraxial
physics model.

### Cardinal And Gaussian Optics

For the system matrix from front reference plane `z1` to rear reference plane
`z2`,

```text
[y2; u2] = [A B; C D] [y1; u1]
```

with object-space index `n1` and image-space index `n2`:

```text
Delta = n1/n2
Phi = -n2*C
det(M) = A*D - B*C = n1/n2
```

If `abs(C) > tol`:

```text
f_prime = -1/C
f       = Delta/C
z_H1    = z1 + (D - Delta)/C
z_H2    = z2 + (1 - A)/C
z_F     = z1 + D/C
z_Fp    = z2 - A/C
FFD     = D/C
BFD     = -A/C
z_N1    = z1 + (D - 1)/C
z_N2    = z2 + (Delta - A)/C
```

If `abs(C) <= tol`, the system is reported as afocal or zero-power and finite
focal/principal points are not forced.

### Aperture Stop And Pupils

Finite aperture candidates are tested using the launch-slope interval:

```text
|A_i*y_obj + B_i*u0| <= a_i
```

The axial aperture stop is the finite aperture candidate with the tightest
finite allowed launch-slope interval for `y_obj = 0`. Stop selection is
axial-first-order in this milestone. Off-axis fields require cumulative
vignetting interval diagnostics, which are not implemented yet.

The app has a `Diagnostic field y` control. For `y = 0`, diagnostics are
labeled axial. For nonzero diagnostic field height, chief/marginal and
invariant diagnostics are computed for that object height using the selected
axial stop, and the app/report include this warning:

```text
Off-axis diagnostics use the selected axial stop. Full off-axis vignetting
interval analysis is not implemented in this milestone.
```

Milestone 2.2 does not perform full off-axis stop re-selection or vignetting
interval analysis.

For a selected stop, the event sequence is split by event identity
(`event_index`), not by `z` alone. This matters when multiple elements share
one plane.

Aperture clipping is evaluated at the selected event plane before the event
matrix. For exit-pupil imaging, a powered selected aperture event
(`thinlens` or `surface`) is included in the post-stop optical path; identity
`stop` and `dummy` events can be excluded because their matrices are identity.

Entrance pupil:

```text
z_EP = z_front + B_pre/A_pre
m_EP = A_pre
r_EP = a_stop/abs(A_pre)
```

Exit pupil:

```text
x_XP = -B_post/D_post
z_XP = z_rear + x_XP
M_XP = T(x_XP)*M_post
m_XP = M_XP(1,1)
r_XP = abs(m_XP)*a_stop
```

### Chief, Marginal, And Phase-Space Diagnostics

For the selected aperture stop:

- Chief ray targets `y_stop = 0`.
- Upper marginal ray targets `y_stop = +a_stop`.
- Lower marginal ray targets `y_stop = -a_stop`.

The app uses `r = [y; u]`. This is not canonical when refractive index changes.
The canonical phase-space coordinate is:

```text
p = n*u
```

The reported Lagrange invariant is:

```text
H = n*(y1*u2 - y2*u1)
```

Raw `y-u` area is reported for comparison, but it is not expected to be
conserved when `n` changes. Invariant conservation is meaningful only for
unblocked ray pairs through the compared path, where the diagnostics mark
`invariant_valid = true`.

Trace-history invariant samples at event planes are recorded as
`state_side = after_event`: the event-plane height is paired with the
after-event slope and medium index.

## Current Limitations

- Paraxial first-order model only.
- Meridional y-z plane only.
- No exact Snell tracing.
- No aberration calculation.
- No Seidel aberration diagnostics.
- No support yet for final image planes before the last enabled element.
