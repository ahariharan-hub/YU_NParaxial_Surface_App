classdef YU_NParaxialSurface_App_V1 < matlab.apps.AppBase
    %YU_NPARAXIALSURFACE_APP_V1 Prescription-driven y-u paraxial app.
    %
    % Run from MATLAB with:
    %   app = YU_NParaxialSurface_App_V1;

    properties (Access = public)
        UIFigure matlab.ui.Figure
    end

    properties (Access = private)
        RootFolder string
        CoreFolder string

        MainGrid matlab.ui.container.GridLayout
        LeftGrid matlab.ui.container.GridLayout
        ActionGrid matlab.ui.container.GridLayout
        ControlPanel matlab.ui.container.Panel
        ControlGrid matlab.ui.container.GridLayout
        TabGroup matlab.ui.container.TabGroup
        PrescriptionButtonGrid matlab.ui.container.GridLayout

        RunButton matlab.ui.control.Button
        ResetButton matlab.ui.control.Button
        StatusLabel matlab.ui.control.Label

        ObjectZField matlab.ui.control.NumericEditField
        FieldMinField matlab.ui.control.NumericEditField
        FieldMaxField matlab.ui.control.NumericEditField
        FieldCountField matlab.ui.control.NumericEditField
        RayCountField matlab.ui.control.NumericEditField
        PresetDropdown matlab.ui.control.DropDown

        RayAxes matlab.ui.control.UIAxes
        SummaryTextArea matlab.ui.control.TextArea
        EquationsTextArea matlab.ui.control.TextArea
        MatrixTable matlab.ui.control.Table
        PrescriptionTable matlab.ui.control.Table

        Data struct
        IsRunning logical = false
        SelectedPrescriptionRows double = []
    end

    methods (Access = private)

        function startup(app)
            app.RootFolder = string(fileparts(mfilename('fullpath')));
            app.CoreFolder = fullfile(app.RootFolder, "core");

            if exist(app.CoreFolder, 'dir')
                addpath(app.CoreFolder);
            else
                app.setStatus("Core helper folder was not found.", true);
                return
            end

            app.loadDefaults();
            app.setStatus("Edit the prescription, then press Run Trace.", false);
        end

        function createComponents(app)
            app.UIFigure = uifigure( ...
                'Name', 'Y-U N Paraxial Surface App V1', ...
                'Position', [70 70 1240 780], ...
                'Color', [0.97 0.97 0.96]);

            app.MainGrid = uigridlayout(app.UIFigure, [1 2]);
            app.MainGrid.ColumnWidth = {290, '1x'};
            app.MainGrid.RowHeight = {'1x'};
            app.MainGrid.Padding = [10 10 10 10];
            app.MainGrid.ColumnSpacing = 10;

            app.LeftGrid = uigridlayout(app.MainGrid, [2 1]);
            app.LeftGrid.Layout.Row = 1;
            app.LeftGrid.Layout.Column = 1;
            app.LeftGrid.RowHeight = {112, '1x'};
            app.LeftGrid.ColumnWidth = {'1x'};
            app.LeftGrid.Padding = [0 0 0 0];
            app.LeftGrid.RowSpacing = 8;

            app.ActionGrid = uigridlayout(app.LeftGrid, [3 1]);
            app.ActionGrid.Layout.Row = 1;
            app.ActionGrid.Layout.Column = 1;
            app.ActionGrid.RowHeight = {36, 32, '1x'};
            app.ActionGrid.ColumnWidth = {'1x'};
            app.ActionGrid.Padding = [0 0 0 0];
            app.ActionGrid.RowSpacing = 6;

            app.RunButton = uibutton(app.ActionGrid, 'push', ...
                'Text', 'Run Trace', ...
                'FontWeight', 'bold', ...
                'ButtonPushedFcn', @(~, ~) app.runTrace());
            app.RunButton.Layout.Row = 1;
            app.RunButton.Layout.Column = 1;

            app.ResetButton = uibutton(app.ActionGrid, 'push', ...
                'Text', 'Reset Defaults', ...
                'ButtonPushedFcn', @(~, ~) app.resetDefaults());
            app.ResetButton.Layout.Row = 2;
            app.ResetButton.Layout.Column = 1;

            app.StatusLabel = uilabel(app.ActionGrid, ...
                'Text', '', ...
                'WordWrap', 'on', ...
                'FontColor', [0.2 0.42 0.2]);
            app.StatusLabel.Layout.Row = 3;
            app.StatusLabel.Layout.Column = 1;

            app.ControlPanel = uipanel(app.LeftGrid, ...
                'Title', 'Trace Controls', ...
                'FontWeight', 'bold');
            app.ControlPanel.Layout.Row = 2;
            app.ControlPanel.Layout.Column = 1;

            app.ControlGrid = uigridlayout(app.ControlPanel, [12 2]);
            app.ControlGrid.ColumnWidth = {'1x', 110};
            app.ControlGrid.RowHeight = repmat({30}, 1, 12);
            app.ControlGrid.RowHeight([1, 8]) = {24, 88};
            app.ControlGrid.Padding = [10 10 10 10];
            app.ControlGrid.RowSpacing = 6;
            app.ControlGrid.ColumnSpacing = 8;

            header = uilabel(app.ControlGrid, ...
                'Text', 'Object and sampling', ...
                'FontWeight', 'bold');
            header.Layout.Row = 1;
            header.Layout.Column = [1 2];

            app.addControlLabel('Object plane z', 2);
            app.ObjectZField = app.addNumericField(2, -120);

            app.addControlLabel('Field min y', 3);
            app.FieldMinField = app.addNumericField(3, -5);

            app.addControlLabel('Field max y', 4);
            app.FieldMaxField = app.addNumericField(4, 5);

            app.addControlLabel('Field count', 5);
            app.FieldCountField = app.addNumericField(5, 5);
            app.FieldCountField.Limits = [1 Inf];
            app.FieldCountField.RoundFractionalValues = 'on';

            app.addControlLabel('Rays per field', 6);
            app.RayCountField = app.addNumericField(6, 9);
            app.RayCountField.Limits = [3 Inf];
            app.RayCountField.RoundFractionalValues = 'on';

            note = uilabel(app.ControlGrid, ...
                'Text', ['Prescription type values: thinlens, surface, stop, dummy. ', ...
                'A finite aperture_radius clips rays at any enabled element. ', ...
                'Only surface elements may change n_before to n_after. ', ...
                'The first enabled finite stop is used to generate sampled ray bundles.'], ...
                'WordWrap', 'on', ...
                'FontColor', [0.25 0.25 0.25]);
            note.Layout.Row = 8;
            note.Layout.Column = [1 2];

            app.addControlLabel('Default prescription', 9);
            app.PresetDropdown = uidropdown(app.ControlGrid, ...
                'Items', { ...
                'Single thin lens', ...
                'Two thin lenses', ...
                'Two-surface thick lens', ...
                'Stop clipping demo'}, ...
                'Value', 'Two thin lenses');
            app.PresetDropdown.Layout.Row = 9;
            app.PresetDropdown.Layout.Column = 2;

            presetButton = uibutton(app.ControlGrid, 'push', ...
                'Text', 'Load Default', ...
                'ButtonPushedFcn', @(~, ~) app.loadSelectedPreset());
            presetButton.Layout.Row = 10;
            presetButton.Layout.Column = [1 2];

            app.TabGroup = uitabgroup(app.MainGrid, ...
                'SelectionChangedFcn', @(~, ~) app.refreshSelectedTab());
            app.TabGroup.Layout.Row = 1;
            app.TabGroup.Layout.Column = 2;

            rayTab = uitab(app.TabGroup, 'Title', 'Ray Diagram');
            rayGrid = uigridlayout(rayTab, [1 1]);
            rayGrid.Padding = [8 8 8 8];
            app.RayAxes = uiaxes(rayGrid);
            app.RayAxes.Layout.Row = 1;
            app.RayAxes.Layout.Column = 1;

            summaryTab = uitab(app.TabGroup, 'Title', 'System Matrix / Image Summary');
            summaryGrid = uigridlayout(summaryTab, [2 1]);
            summaryGrid.RowHeight = {'1x', '1x'};
            summaryGrid.Padding = [8 8 8 8];
            summaryGrid.RowSpacing = 8;

            app.SummaryTextArea = uitextarea(summaryGrid, ...
                'Editable', 'off', ...
                'FontName', 'Consolas');
            if isprop(app.SummaryTextArea, 'WordWrap')
                app.SummaryTextArea.WordWrap = 'off';
            end
            app.SummaryTextArea.Layout.Row = 1;
            app.SummaryTextArea.Layout.Column = 1;

            app.MatrixTable = uitable(summaryGrid);
            app.MatrixTable.Layout.Row = 2;
            app.MatrixTable.Layout.Column = 1;

            equationsTab = uitab(app.TabGroup, 'Title', 'Equations');
            equationsGrid = uigridlayout(equationsTab, [1 1]);
            equationsGrid.Padding = [8 8 8 8];
            app.EquationsTextArea = uitextarea(equationsGrid, ...
                'Editable', 'off', ...
                'FontName', 'Consolas', ...
                'Value', app.equationText());
            if isprop(app.EquationsTextArea, 'WordWrap')
                app.EquationsTextArea.WordWrap = 'off';
            end
            app.EquationsTextArea.Layout.Row = 1;
            app.EquationsTextArea.Layout.Column = 1;

            prescriptionTab = uitab(app.TabGroup, 'Title', 'Prescription Table');
            prescriptionGrid = uigridlayout(prescriptionTab, [2 1]);
            prescriptionGrid.RowHeight = {78, '1x'};
            prescriptionGrid.ColumnWidth = {'1x'};
            prescriptionGrid.Padding = [8 8 8 8];
            prescriptionGrid.RowSpacing = 8;

            app.PrescriptionButtonGrid = uigridlayout(prescriptionGrid, [2 7]);
            app.PrescriptionButtonGrid.Layout.Row = 1;
            app.PrescriptionButtonGrid.Layout.Column = 1;
            app.PrescriptionButtonGrid.ColumnWidth = repmat({'1x'}, 1, 7);
            app.PrescriptionButtonGrid.RowHeight = {32, 32};
            app.PrescriptionButtonGrid.Padding = [0 0 0 0];
            app.PrescriptionButtonGrid.ColumnSpacing = 6;
            app.PrescriptionButtonGrid.RowSpacing = 6;

            app.addPrescriptionButton('Add Thin Lens', 1, 1, ...
                @(~, ~) app.addPrescriptionRow("thinlens"));
            app.addPrescriptionButton('Add Surface', 1, 2, ...
                @(~, ~) app.addPrescriptionRow("surface"));
            app.addPrescriptionButton('Add Stop', 1, 3, ...
                @(~, ~) app.addPrescriptionRow("stop"));
            app.addPrescriptionButton('Add Dummy', 1, 4, ...
                @(~, ~) app.addPrescriptionRow("dummy"));
            app.addPrescriptionButton('Duplicate Row', 1, 5, ...
                @(~, ~) app.duplicatePrescriptionRow());
            app.addPrescriptionButton('Delete Selected Row', 1, 6, ...
                @(~, ~) app.deleteSelectedPrescriptionRows());
            app.addPrescriptionButton('Sort Prescription', 1, 7, ...
                @(~, ~) app.sortPrescriptionTable());

            app.addPrescriptionButton('Check Prescription', 2, 1, ...
                @(~, ~) app.checkPrescription());
            app.addPrescriptionButton('Save Prescription CSV', 2, 2, ...
                @(~, ~) app.savePrescriptionCsv());
            app.addPrescriptionButton('Load Prescription CSV', 2, 3, ...
                @(~, ~) app.loadPrescriptionCsv());
            app.addPrescriptionButton('Save Prescription MAT', 2, 4, ...
                @(~, ~) app.savePrescriptionMat());
            app.addPrescriptionButton('Load Prescription MAT', 2, 5, ...
                @(~, ~) app.loadPrescriptionMat());
            app.addPrescriptionButton('Export Ray Table CSV', 2, 6, ...
                @(~, ~) app.exportRayTableCsv());
            app.addPrescriptionButton('Export Summary TXT', 2, 7, ...
                @(~, ~) app.exportSummaryTxt());

            app.PrescriptionTable = uitable(prescriptionGrid);
            app.PrescriptionTable.Layout.Row = 2;
            app.PrescriptionTable.Layout.Column = 1;
            app.PrescriptionTable.ColumnEditable = true(1, 10);
            app.PrescriptionTable.CellEditCallback = @(~, ~) app.requestTrace();
            app.PrescriptionTable.CellSelectionCallback = ...
                @(~, event) app.selectPrescriptionRows(event);
        end

        function addPrescriptionButton(app, labelText, row, column, callbackFcn)
            button = uibutton(app.PrescriptionButtonGrid, 'push', ...
                'Text', labelText, ...
                'ButtonPushedFcn', callbackFcn);
            button.Layout.Row = row;
            button.Layout.Column = column;
        end

        function addControlLabel(app, textValue, row)
            label = uilabel(app.ControlGrid, ...
                'Text', textValue, ...
                'HorizontalAlignment', 'left');
            label.Layout.Row = row;
            label.Layout.Column = 1;
        end

        function field = addNumericField(app, row, value)
            field = uieditfield(app.ControlGrid, 'numeric', ...
                'Value', value, ...
                'ValueChangedFcn', @(~, ~) app.requestTrace());
            field.Layout.Row = row;
            field.Layout.Column = 2;
        end

        function lines = equationText(~)
            lines = {
                'N-PARAXIAL-SURFACE V1 CONVENTIONS'
                '================================='
                ''
                '1. Direction and ray vector'
                '   Forward propagation is along increasing z.'
                '   Ray vector: r = [y; u], where u = dy/dz.'
                '   This app traces meridional rays in the y-z plane only.'
                ''
                '2. Surface-radius convention'
                '   R > 0: center of curvature is at larger z than the surface vertex.'
                '   R < 0: center of curvature is at smaller z than the surface vertex.'
                '   R = Inf: plane refracting surface.'
                ''
                '3. Translation'
                '   T(d) = [1 d; 0 1]'
                '   d = z_out - z_in.'
                ''
                '4. Thin lens'
                '   L(f) = [1 0; -1/f 1]'
                '   Thin lenses do not change medium index: n_before == n_after.'
                ''
                '5. Paraxial refracting spherical surface'
                '   S(n1,n2,R) = [1 0; (n1-n2)/(n2*R) n1/n2]'
                '   Only surface elements may change n_before to n_after.'
                ''
                '6. Stop and dummy elements'
                '   Stop and dummy elements use the identity matrix.'
                '   They do not change u or medium index.'
                '   A finite aperture_radius clips rays at the element plane.'
                ''
                '7. Prescription order'
                '   Enabled elements are applied by increasing z, then event_order.'
                '   For equal z and equal event_order, stable table row order is used.'
                '   The first enabled row defines the object-space/input medium.'
                ''
                '8. Presets and data handling'
                '   Built-in presets are available for: single thin lens, two thin lenses,'
                '   two-surface thick lens, and a stop clipping demo.'
                '   Prescriptions can be checked, saved, and loaded as CSV or MAT files.'
                '   Ray result tables can be exported as CSV after a trace is run.'
                '   The text summary can be exported after a trace is run.'
                ''
                '9. Image solve'
                '   Build M_ref = [A B; C D] from object plane to z_ref.'
                '   z_ref is the last enabled element position.'
                '   After translating by x: B_total = B + x*D.'
                '   The image condition is B_total = 0, so x = -B/D.'
                '   This milestone accepts only z_img >= z_ref.'
                ''
                '10. Current limitations'
                '   Paraxial first-order model only.'
                '   No exact Snell tracing.'
                '   No aberration calculation.'
                '   No advanced pupil diagnostics.'
                '   No support yet for final image planes before the last enabled element.'
            };
        end

        function loadDefaults(app)
            app.ObjectZField.Value = -120;
            app.FieldMinField.Value = -5;
            app.FieldMaxField.Value = 5;
            app.FieldCountField.Value = 5;
            app.RayCountField.Value = 9;
            if ~isempty(app.PresetDropdown) && isvalid(app.PresetDropdown)
                app.PresetDropdown.Value = 'Two thin lenses';
            end
            app.PrescriptionTable.Data = nparaxial_default_prescription_yu();
            app.SelectedPrescriptionRows = [];
            app.Data = struct();
        end

        function resetDefaults(app)
            app.loadDefaults();
            app.setStatus("Defaults loaded. Press Run Trace.", false);
            cla(app.RayAxes);
            app.SummaryTextArea.Value = {};
            app.MatrixTable.Data = table();
        end

        function loadSelectedPreset(app)
            try
                prescription = nparaxial_default_prescription_yu( ...
                    app.PresetDropdown.Value);
                app.PrescriptionTable.Data = table_to_prescription_yu(prescription);
                app.SelectedPrescriptionRows = [];
                app.Data = struct();
                app.requestTrace();
                app.setStatus("Loaded default prescription: " + ...
                    string(app.PresetDropdown.Value) + ".", false);
            catch ME
                app.setStatus("Error: " + string(ME.message), true);
            end
        end

        function checkPrescription(app)
            try
                prescription = table_to_prescription_yu(app.PrescriptionTable.Data);
                app.PrescriptionTable.Data = prescription;
                enabledCount = sum(prescription.enabled);
                app.setStatus(sprintf( ...
                    'Prescription OK: %d enabled element(s).', enabledCount), false);
            catch ME
                app.setStatus("Prescription error: " + string(ME.message), true);
            end
        end

        function savePrescriptionCsv(app)
            try
                [fileName, pathName] = uiputfile( ...
                    {'*.csv', 'CSV files (*.csv)'}, ...
                    'Save Prescription CSV');
                if isequal(fileName, 0)
                    app.setStatus("Save prescription CSV canceled.", false);
                    return
                end

                filename = fullfile(pathName, fileName);
                save_prescription_csv_yu(app.PrescriptionTable.Data, filename);
                app.setStatus("Saved prescription CSV: " + string(filename), false);
            catch ME
                app.setStatus("Save CSV error: " + string(ME.message), true);
            end
        end

        function loadPrescriptionCsv(app)
            try
                [fileName, pathName] = uigetfile( ...
                    {'*.csv', 'CSV files (*.csv)'}, ...
                    'Load Prescription CSV');
                if isequal(fileName, 0)
                    app.setStatus("Load prescription CSV canceled.", false);
                    return
                end

                filename = fullfile(pathName, fileName);
                app.PrescriptionTable.Data = load_prescription_csv_yu(filename);
                app.SelectedPrescriptionRows = [];
                app.Data = struct();
                app.requestTrace();
                app.setStatus("Loaded prescription CSV: " + string(filename), false);
            catch ME
                app.setStatus("Load CSV error: " + string(ME.message), true);
            end
        end

        function savePrescriptionMat(app)
            try
                [fileName, pathName] = uiputfile( ...
                    {'*.mat', 'MAT files (*.mat)'}, ...
                    'Save Prescription MAT');
                if isequal(fileName, 0)
                    app.setStatus("Save prescription MAT canceled.", false);
                    return
                end

                filename = fullfile(pathName, fileName);
                save_prescription_mat_yu(app.PrescriptionTable.Data, filename);
                app.setStatus("Saved prescription MAT: " + string(filename), false);
            catch ME
                app.setStatus("Save MAT error: " + string(ME.message), true);
            end
        end

        function loadPrescriptionMat(app)
            try
                [fileName, pathName] = uigetfile( ...
                    {'*.mat', 'MAT files (*.mat)'}, ...
                    'Load Prescription MAT');
                if isequal(fileName, 0)
                    app.setStatus("Load prescription MAT canceled.", false);
                    return
                end

                filename = fullfile(pathName, fileName);
                app.PrescriptionTable.Data = load_prescription_mat_yu(filename);
                app.SelectedPrescriptionRows = [];
                app.Data = struct();
                app.requestTrace();
                app.setStatus("Loaded prescription MAT: " + string(filename), false);
            catch ME
                app.setStatus("Load MAT error: " + string(ME.message), true);
            end
        end

        function exportRayTableCsv(app)
            try
                if isempty(app.Data) || isempty(fieldnames(app.Data))
                    app.setStatus("Run Trace before exporting the ray table.", true);
                    return
                end

                [fileName, pathName] = uiputfile( ...
                    {'*.csv', 'CSV files (*.csv)'}, ...
                    'Export Ray Table CSV');
                if isequal(fileName, 0)
                    app.setStatus("Export ray table canceled.", false);
                    return
                end

                filename = fullfile(pathName, fileName);
                writetable(app.makeRayExportTable(), filename);
                app.setStatus("Exported ray table CSV: " + string(filename), false);
            catch ME
                app.setStatus("Export rays error: " + string(ME.message), true);
            end
        end

        function exportSummaryTxt(app)
            try
                if isempty(app.Data) || isempty(fieldnames(app.Data))
                    app.setStatus("Run Trace before exporting the summary.", true);
                    return
                end

                [fileName, pathName] = uiputfile( ...
                    {'*.txt', 'Text files (*.txt)'}, ...
                    'Export Summary TXT');
                if isequal(fileName, 0)
                    app.setStatus("Export summary canceled.", false);
                    return
                end

                filename = fullfile(pathName, fileName);
                app.writeSummaryTextFile(filename);
                app.setStatus("Exported summary TXT: " + string(filename), false);
            catch ME
                app.setStatus("Export summary error: " + string(ME.message), true);
            end
        end

        function runTrace(app)
            if app.IsRunning
                return
            end

            app.IsRunning = true;
            cleanup = onCleanup(@() app.finishTrace());

            try
                app.setStatus("Tracing...", false);
                drawnow limitrate

                params = app.readParameters();
                prescription = nparaxial_validate_prescription_yu(app.PrescriptionTable.Data);
                img = nparaxial_solve_image_plane_yu(prescription, params.z_obj);

                if ~img.isFinite
                    error(img.note);
                end
                if img.z_img < img.z_ref - 1e-12
                    error(['This milestone supports only final real image planes ', ...
                        'after the last enabled element. Virtual/intermediate images ', ...
                        'before the last enabled element are not supported yet.']);
                end
                if img.z_img <= params.z_obj
                    error('Solved image plane is not after the object plane.');
                end

                data = app.computeCase(params, prescription, img);
                app.Data = data;
                app.PrescriptionTable.Data = data.prescription;
                app.refreshSelectedTab();
                app.setStatus("Trace complete.", false);
            catch ME
                app.setStatus("Error: " + string(ME.message), true);
            end
        end

        function finishTrace(app)
            app.IsRunning = false;
        end

        function requestTrace(app)
            app.setStatus("Parameters changed. Press Run Trace.", false);
        end

        function params = readParameters(app)
            params = struct();
            params.z_obj = app.ObjectZField.Value;
            params.y_min = app.FieldMinField.Value;
            params.y_max = app.FieldMaxField.Value;
            params.Nfield = round(app.FieldCountField.Value);
            params.Nrays = round(app.RayCountField.Value);

            if ~isfinite(params.z_obj)
                error('Object plane z must be finite.');
            end
            if ~isfinite(params.y_min) || ~isfinite(params.y_max)
                error('Field min and max must be finite.');
            end
            if params.Nfield < 1
                error('Field count must be at least 1.');
            end
            if params.Nrays < 3
                error('Rays per field must be at least 3.');
            end
            if mod(params.Nrays, 2) == 0
                params.Nrays = params.Nrays + 1;
                app.RayCountField.Value = params.Nrays;
            end
        end

        function data = computeCase(app, params, prescription, img)
            yFields = app.buildFieldHeights(params);
            primaryStop = app.findPrimaryStop(prescription, params.z_obj, img.z_img);

            bundleSet = struct([]);
            field_index = zeros(numel(yFields), 1);
            y_object = zeros(numel(yFields), 1);
            y_image_predicted = zeros(numel(yFields), 1);
            y_image_measured = NaN(numel(yFields), 1);
            image_error = NaN(numel(yFields), 1);
            max_ray_spread = NaN(numel(yFields), 1);
            rms_ray_spread = NaN(numel(yFields), 1);
            num_passed = zeros(numel(yFields), 1);
            num_blocked = zeros(numel(yFields), 1);

            for q = 1:numel(yFields)
                yObj = yFields(q);
                if ~isempty(primaryStop)
                    rays = nparaxial_make_stop_sampled_rays_yu( ...
                        prescription, params.z_obj, yObj, ...
                        primaryStop.z, primaryStop.aperture_radius, params.Nrays);
                else
                    rays = app.makeFanRays(params.z_obj, yObj, params.Nrays);
                end
                rays.name = "field_" + string(q) + "_" + rays.name;

                bundle = nparaxial_trace_bundle_yu(rays, prescription, img.z_img);
                diag = app.imageDiagnostics(bundle);

                bundleSet(q).field_index = q;
                bundleSet(q).y_obj = yObj;
                bundleSet(q).rays = rays;
                bundleSet(q).bundle = bundle;
                bundleSet(q).diag = diag;

                field_index(q) = q;
                y_object(q) = yObj;
                y_image_predicted(q) = img.m * yObj;
                y_image_measured(q) = diag.mean_yf;
                image_error(q) = diag.mean_yf - img.m*yObj;
                max_ray_spread(q) = diag.max_abs_delta_yf;
                rms_ray_spread(q) = diag.rms_delta_yf;
                num_passed(q) = sum(diag.table.traced);
                num_blocked(q) = sum(~diag.table.traced);
            end

            fieldTable = table;
            fieldTable.field_index = field_index;
            fieldTable.y_object = y_object;
            fieldTable.y_image_predicted = y_image_predicted;
            fieldTable.y_image_measured = y_image_measured;
            fieldTable.image_error = image_error;
            fieldTable.max_ray_spread = max_ray_spread;
            fieldTable.rms_ray_spread = rms_ray_spread;
            fieldTable.num_passed = num_passed;
            fieldTable.num_blocked = num_blocked;

            matrixTable = app.makeMatrixTable(img, params.z_obj);
            summaryLines = app.makeSummaryLines( ...
                params, prescription, img, primaryStop, fieldTable);

            data = struct();
            data.params = params;
            data.prescription = prescription;
            data.enabledElements = nparaxial_enabled_elements_yu(prescription);
            data.img = img;
            data.yFields = yFields(:);
            data.primaryStop = primaryStop;
            data.bundleSet = bundleSet;
            data.fieldTable = fieldTable;
            data.matrixTable = matrixTable;
            data.summaryLines = summaryLines;
        end

        function yFields = buildFieldHeights(~, params)
            if params.Nfield == 1
                yFields = mean([params.y_min, params.y_max]);
            else
                yFields = linspace(params.y_min, params.y_max, params.Nfield);
            end
            yFields = yFields(:);
        end

        function stop = findPrimaryStop(~, prescription, zObj, zFinal)
            stop = [];
            elements = nparaxial_enabled_elements_yu(prescription);
            mask = elements.type == "stop" & ...
                elements.z > zObj & elements.z < zFinal & ...
                isfinite(elements.aperture_radius);
            idx = find(mask, 1, 'first');
            if isempty(idx)
                return
            end
            stop = elements(idx, :);
        end

        function selectPrescriptionRows(app, event)
            if isempty(event.Indices)
                app.SelectedPrescriptionRows = [];
            else
                app.SelectedPrescriptionRows = unique(event.Indices(:, 1)).';
            end
        end

        function addPrescriptionRow(app, elementType)
            try
                T = nparaxial_validate_prescription_yu(app.PrescriptionTable.Data);
                newRow = app.defaultPrescriptionRow(T, elementType);
                app.PrescriptionTable.Data = [T; newRow];
                app.SelectedPrescriptionRows = height(app.PrescriptionTable.Data);
                app.requestTrace();
            catch ME
                app.setStatus("Error: " + string(ME.message), true);
            end
        end

        function duplicatePrescriptionRow(app)
            try
                T = nparaxial_validate_prescription_yu(app.PrescriptionTable.Data);
                rows = app.SelectedPrescriptionRows;
                rows = rows(rows >= 1 & rows <= height(T));
                if isempty(rows)
                    app.setStatus("Select a prescription row to duplicate.", false);
                    return
                end

                row = rows(1);
                newRow = T(row, :);
                newRow.element_id = app.uniqueElementId(T, app.prefixForType(newRow.type));
                newRow.event_order = max(T.event_order) + 1;
                app.PrescriptionTable.Data = [T; newRow];
                app.SelectedPrescriptionRows = height(app.PrescriptionTable.Data);
                app.requestTrace();
            catch ME
                app.setStatus("Error: " + string(ME.message), true);
            end
        end

        function deleteSelectedPrescriptionRows(app)
            T = app.PrescriptionTable.Data;
            if ~istable(T) || isempty(T)
                app.setStatus("Prescription table is empty.", false);
                return
            end

            rows = app.SelectedPrescriptionRows;
            rows = rows(rows >= 1 & rows <= height(T));
            if isempty(rows)
                app.setStatus("Select one or more prescription rows to delete.", false);
                return
            end
            if numel(rows) >= height(T)
                app.setStatus("At least one prescription row must remain.", true);
                return
            end

            T(rows, :) = [];
            app.PrescriptionTable.Data = T;
            app.SelectedPrescriptionRows = [];
            app.requestTrace();
        end

        function sortPrescriptionTable(app)
            try
                T = nparaxial_validate_prescription_yu(app.PrescriptionTable.Data);
                rowOrder = (1:height(T)).';
                [~, idx] = sortrows([T.z, T.event_order, rowOrder]);
                app.PrescriptionTable.Data = T(idx, :);
                app.SelectedPrescriptionRows = [];
                app.requestTrace();
            catch ME
                app.setStatus("Error: " + string(ME.message), true);
            end
        end

        function newRow = defaultPrescriptionRow(app, T, elementType)
            elementType = lower(strtrim(string(elementType)));
            zValues = T.z(isfinite(T.z));
            if isempty(zValues)
                zDefault = 0;
            else
                zDefault = max(zValues) + 20;
            end

            if isempty(T)
                nBefore = 1;
                eventOrder = 1;
            else
                nBefore = T.n_after(end);
                eventOrder = max(T.event_order) + 1;
            end

            nAfter = nBefore;
            aperture = 50;
            focalLength = Inf;
            radiusR = Inf;

            switch elementType
                case "thinlens"
                    idPrefix = "L";
                    focalLength = 100;
                case "surface"
                    idPrefix = "S";
                    radiusR = 100;
                    if abs(nBefore - 1) <= 1e-12
                        nAfter = 1.5;
                    end
                case "stop"
                    idPrefix = "STOP";
                    aperture = 10;
                case "dummy"
                    idPrefix = "DUMMY";
                    aperture = Inf;
                otherwise
                    error('Unsupported element type "%s".', elementType);
            end

            newRow = table( ...
                app.uniqueElementId(T, idPrefix), ...
                eventOrder, ...
                elementType, ...
                zDefault, ...
                aperture, ...
                focalLength, ...
                radiusR, ...
                nBefore, ...
                nAfter, ...
                true, ...
                'VariableNames', { ...
                'element_id', 'event_order', 'type', 'z', ...
                'aperture_radius', 'focal_length', 'radius_R', ...
                'n_before', 'n_after', 'enabled'});
        end

        function id = uniqueElementId(~, T, prefix)
            prefix = upper(string(prefix));
            existing = string(T.element_id);
            idx = 1;
            id = prefix + string(idx);
            while any(existing == id)
                idx = idx + 1;
                id = prefix + string(idx);
            end
        end

        function prefix = prefixForType(~, elementType)
            switch lower(strtrim(string(elementType)))
                case "thinlens"
                    prefix = "L";
                case "surface"
                    prefix = "S";
                case "stop"
                    prefix = "STOP";
                case "dummy"
                    prefix = "DUMMY";
                otherwise
                    prefix = "E";
            end
        end

        function rays = makeFanRays(~, zObj, yObj, nRays)
            slopes = linspace(-0.04, 0.04, nRays).';
            names = "ray_" + string((1:nRays).');
            mid = (nRays + 1)/2;
            names(1) = "lower_marginal";
            names(mid) = "chief";
            names(end) = "upper_marginal";

            rays = table;
            rays.name = names;
            rays.z0 = repmat(zObj, nRays, 1);
            rays.y0 = repmat(yObj, nRays, 1);
            rays.u0 = slopes;
            rays.z_target = NaN(nRays, 1);
            rays.y_target = NaN(nRays, 1);
        end

        function diag = imageDiagnostics(~, bundle)
            nRays = numel(bundle);
            names = strings(nRays, 1);
            traced = false(nRays, 1);
            yf = NaN(nRays, 1);
            uf = NaN(nRays, 1);
            blocked_z = NaN(nRays, 1);
            blocked_y = NaN(nRays, 1);
            blocked_aperture = NaN(nRays, 1);

            for k = 1:nRays
                names(k) = string(bundle(k).name);
                traced(k) = bundle(k).trc;
                yf(k) = bundle(k).yf;
                uf(k) = bundle(k).uf;
                blocked_z(k) = bundle(k).res.blocked_at_z;
                blocked_y(k) = bundle(k).res.blocked_y;
                blocked_aperture(k) = bundle(k).res.blocked_aperture;
            end

            passed = traced & isfinite(yf);
            delta_yf = NaN(nRays, 1);
            if any(passed)
                mean_yf = mean(yf(passed));
                delta_yf(passed) = yf(passed) - mean_yf;
                max_abs_delta_yf = max(abs(delta_yf(passed)));
                rms_delta_yf = sqrt(mean(delta_yf(passed).^2));
            else
                mean_yf = NaN;
                max_abs_delta_yf = NaN;
                rms_delta_yf = NaN;
            end

            T = table;
            T.name = names;
            T.traced = traced;
            T.yf = yf;
            T.uf = uf;
            T.delta_yf = delta_yf;
            T.blocked_z = blocked_z;
            T.blocked_y = blocked_y;
            T.blocked_aperture = blocked_aperture;

            diag = struct();
            diag.table = T;
            diag.mean_yf = mean_yf;
            diag.max_abs_delta_yf = max_abs_delta_yf;
            diag.rms_delta_yf = rms_delta_yf;
        end

        function T = makeRayExportTable(app)
            data = app.Data;
            nRows = 0;
            for q = 1:numel(data.bundleSet)
                nRows = nRows + numel(data.bundleSet(q).bundle);
            end

            field_index = zeros(nRows, 1);
            y_object = zeros(nRows, 1);
            ray_name = strings(nRows, 1);
            z0 = NaN(nRows, 1);
            y0 = NaN(nRows, 1);
            u0 = NaN(nRows, 1);
            traced = false(nRows, 1);
            y_final = NaN(nRows, 1);
            u_final = NaN(nRows, 1);
            delta_y_final = NaN(nRows, 1);
            blocked_element_id = strings(nRows, 1);
            blocked_z = NaN(nRows, 1);
            blocked_y = NaN(nRows, 1);
            blocked_aperture = NaN(nRows, 1);

            row = 0;
            for q = 1:numel(data.bundleSet)
                bundle = data.bundleSet(q).bundle;
                diagTable = data.bundleSet(q).diag.table;
                for r = 1:numel(bundle)
                    row = row + 1;
                    rayIn = bundle(r).ray_in;
                    res = bundle(r).res;

                    field_index(row) = data.bundleSet(q).field_index;
                    y_object(row) = data.bundleSet(q).y_obj;
                    ray_name(row) = bundle(r).name;
                    z0(row) = rayIn(1);
                    y0(row) = rayIn(2);
                    u0(row) = rayIn(3);
                    traced(row) = bundle(r).trc;
                    y_final(row) = bundle(r).yf;
                    u_final(row) = bundle(r).uf;
                    delta_y_final(row) = diagTable.delta_yf(r);
                    blocked_element_id(row) = res.blocked_element_id;
                    blocked_z(row) = res.blocked_at_z;
                    blocked_y(row) = res.blocked_y;
                    blocked_aperture(row) = res.blocked_aperture;
                end
            end

            T = table( ...
                field_index, y_object, ray_name, z0, y0, u0, traced, ...
                y_final, u_final, delta_y_final, blocked_element_id, ...
                blocked_z, blocked_y, blocked_aperture);
        end

        function writeSummaryTextFile(app, filename)
            fid = fopen(filename, 'w');
            if fid < 0
                error('Could not open "%s" for writing.', filename);
            end
            cleanup = onCleanup(@() fclose(fid));

            summaryLines = string(app.Data.summaryLines(:));
            for k = 1:numel(summaryLines)
                fprintf(fid, '%s\n', summaryLines(k));
            end

            fprintf(fid, '\nSystem matrix / image table\n');
            fprintf(fid, '---------------------------\n');
            matrixTable = app.Data.matrixTable;
            for k = 1:height(matrixTable)
                fprintf(fid, '%s\t%.12g\n', ...
                    matrixTable.quantity(k), matrixTable.value(k));
            end
        end

        function T = makeMatrixTable(~, img, zObj)
            quantity = [
                "z_object"
                "z_reference"
                "z_image"
                "x_after_reference"
                "A_ref"
                "B_ref"
                "C_ref"
                "D_ref"
                "A_img"
                "B_img"
                "C_img"
                "D_img"
                "transverse_m"
                "B_residual"
            ];

            value = [
                zObj
                img.z_ref
                img.z_img
                img.x_after_ref
                img.A_ref
                img.B_ref
                img.C_ref
                img.D_ref
                img.A_img
                img.B_img
                img.C_img
                img.D_img
                img.m
                img.B_residual
            ];

            T = table(quantity, value);
        end

        function lines = makeSummaryLines(~, params, prescription, img, primaryStop, fieldTable)
            elements = nparaxial_enabled_elements_yu(prescription);
            inputMedium = elements.n_before(1);
            outputMedium = elements.n_after(end);
            totalPassed = sum(fieldTable.num_passed);
            totalBlocked = sum(fieldTable.num_blocked);
            maxAbsError = max(abs(fieldTable.image_error), [], 'omitnan');
            maxSpread = max(fieldTable.max_ray_spread, [], 'omitnan');

            lines = {
                'N-element paraxial y-u summary'
                '------------------------------'
                sprintf('Enabled elements = %d', height(elements))
                sprintf('Object plane z = %.6g', params.z_obj)
                sprintf('Object-space/input n = %.6g', inputMedium)
                sprintf('Image-space/output n = %.6g', outputMedium)
                sprintf('Reference element z = %.6g', img.z_ref)
                sprintf('Image plane z = %.6g', img.z_img)
                sprintf('Distance after reference x = %.6g', img.x_after_ref)
                sprintf('Transverse magnification m = %.6g', img.m)
                sprintf('B residual at image = %.3e', img.B_residual)
                sprintf('Field heights = %.6g to %.6g', min(fieldTable.y_object), max(fieldTable.y_object))
                sprintf('Fields = %d, rays per field = %d', params.Nfield, params.Nrays)
                sprintf('Passed rays = %d, blocked rays = %d', totalPassed, totalBlocked)
                sprintf('Max image error = %.3e', maxAbsError)
                sprintf('Max ray spread = %.3e', maxSpread)
                ''
                'Element sequence'
                '----------------'
            };

            for k = 1:height(elements)
                lines{end+1, 1} = sprintf( ...
                    '%s: order=%.6g, type=%s, z=%.6g, aperture=%.6g, f=%.6g, R=%.6g, n %.6g -> %.6g', ...
                    elements.element_id(k), elements.event_order(k), ...
                    elements.type(k), elements.z(k), elements.aperture_radius(k), ...
                    elements.focal_length(k), elements.radius_R(k), ...
                    elements.n_before(k), elements.n_after(k)); %#ok<AGROW>
            end

            if isempty(primaryStop)
                lines{end+1, 1} = '';
                lines{end+1, 1} = 'Ray generation used a simple launch-angle fan because no finite stop was available.';
            else
                lines{end+1, 1} = '';
                lines{end+1, 1} = sprintf( ...
                    'Ray generation targeted stop "%s" at z = %.6g, radius = %.6g.', ...
                    primaryStop.element_id(1), primaryStop.z(1), ...
                    primaryStop.aperture_radius(1));
            end
        end

        function refreshSelectedTab(app)
            if isempty(app.Data) || isempty(fieldnames(app.Data))
                return
            end

            titleText = string(app.TabGroup.SelectedTab.Title);
            switch titleText
                case "Ray Diagram"
                    app.plotRayDiagram();
                case "System Matrix / Image Summary"
                    app.updateSummary();
                otherwise
                    % Prescription table is directly editable.
            end
        end

        function plotRayDiagram(app)
            ax = app.RayAxes;
            cla(ax);
            hold(ax, 'on');
            grid(ax, 'on');
            box(ax, 'on');

            data = app.Data;
            yVals = [];
            zVals = [data.params.z_obj; data.enabledElements.z; data.img.z_img];

            for q = 1:numel(data.bundleSet)
                bundle = data.bundleSet(q).bundle;
                for r = 1:numel(bundle)
                    res = bundle(r).res;
                    for s = 1:numel(res.seg_z)
                        zSeg = res.seg_z{s};
                        ySeg = res.seg_y{s};
                        if numel(zSeg) < 2 || numel(ySeg) < 2
                            continue
                        end
                        [color, width, style] = app.rayStyle( ...
                            bundle(r).name, ~bundle(r).trc);
                        plot(ax, zSeg, ySeg, ...
                            'Color', color, ...
                            'LineWidth', width, ...
                            'LineStyle', style);
                        yVals = [yVals; ySeg(:)]; %#ok<AGROW>
                        zVals = [zVals; zSeg(:)]; %#ok<AGROW>
                    end
                    if ~bundle(r).trc && isfinite(res.blocked_at_z)
                        plot(ax, res.blocked_at_z, res.blocked_y, 'x', ...
                            'Color', [0.75 0.1 0.1], ...
                            'LineWidth', 1.5, ...
                            'MarkerSize', 7);
                    end
                end
            end

            finiteApertures = data.enabledElements.aperture_radius( ...
                isfinite(data.enabledElements.aperture_radius));
            if ~isempty(finiteApertures)
                yVals = [yVals; finiteApertures; -finiteApertures];
            end

            if isempty(yVals) || all(~isfinite(yVals))
                yVals = [-1; 1];
            end

            yMin = min(yVals);
            yMax = max(yVals);
            if yMin == yMax
                yMin = yMin - 1;
                yMax = yMax + 1;
            end
            yPad = 0.12*(yMax - yMin);
            yLim = [yMin - yPad, yMax + yPad];
            ylim(ax, yLim);

            for k = 1:height(data.enabledElements)
                element = data.enabledElements(k, :);
                app.drawElement(ax, element, yLim);
            end

            plot(ax, [data.img.z_img, data.img.z_img], yLim, ...
                ':', 'Color', [0.25 0.25 0.25], 'LineWidth', 1.2);
            text(ax, data.img.z_img, yLim(2), ' image', ...
                'VerticalAlignment', 'top', ...
                'Color', [0.25 0.25 0.25]);

            xMin = min(zVals);
            xMax = max(zVals);
            if xMin == xMax
                xMin = xMin - 1;
                xMax = xMax + 1;
            end
            xPad = 0.04*(xMax - xMin);
            xlim(ax, [xMin - xPad, xMax + xPad]);

            xlabel(ax, 'z');
            ylabel(ax, 'y');
            title(ax, 'N-element paraxial ray trace');
            hold(ax, 'off');
        end

        function drawElement(~, ax, element, yLim)
            z = element.z(1);
            a = element.aperture_radius(1);
            typeName = element.type(1);
            colorSet = lines(4);

            switch typeName
                case "thinlens"
                    color = colorSet(1, :);
                    lineStyle = '-';
                case "surface"
                    color = colorSet(2, :);
                    lineStyle = '-.';
                case "stop"
                    color = colorSet(3, :);
                    lineStyle = '--';
                otherwise
                    color = colorSet(4, :);
                    lineStyle = ':';
            end

            if isfinite(a)
                plot(ax, [z, z], [-a, a], ...
                    'Color', color, ...
                    'LineStyle', lineStyle, ...
                    'LineWidth', 2.0);
                plot(ax, z, a, 'v', 'Color', color, 'MarkerSize', 5);
                plot(ax, z, -a, '^', 'Color', color, 'MarkerSize', 5);
            else
                plot(ax, [z, z], yLim, ...
                    'Color', color, ...
                    'LineStyle', lineStyle, ...
                    'LineWidth', 1.1);
            end

            text(ax, z, yLim(1), ...
                " " + element.element_id(1) + " (" + typeName + ")", ...
                'VerticalAlignment', 'bottom', ...
                'Color', color);
        end

        function [color, width, style] = rayStyle(~, rayName, isBlocked)
            rayName = string(rayName);
            width = 0.8;
            style = '-';
            color = [0.56 0.56 0.56];

            if contains(rayName, "chief")
                color = [0.82 0.12 0.12];
                width = 1.4;
            elseif contains(rayName, "upper_marginal")
                color = [0.12 0.34 0.75];
                width = 1.2;
            elseif contains(rayName, "lower_marginal")
                color = [0.12 0.58 0.22];
                width = 1.2;
            end

            if isBlocked
                style = '--';
                width = width + 0.2;
            end
        end

        function updateSummary(app)
            app.SummaryTextArea.Value = app.Data.summaryLines;
            app.MatrixTable.Data = app.Data.matrixTable;
        end

        function setStatus(app, message, isError)
            if isempty(app.StatusLabel) || ~isvalid(app.StatusLabel)
                return
            end
            app.StatusLabel.Text = char(message);
            if isError
                app.StatusLabel.FontColor = [0.72 0.12 0.12];
            else
                app.StatusLabel.FontColor = [0.2 0.42 0.2];
            end
            drawnow limitrate
        end
    end

    methods (Access = public)

        function app = YU_NParaxialSurface_App_V1
            createComponents(app);
            registerApp(app, app.UIFigure);
            runStartupFcn(app, @startup);
            if nargout == 0
                clear app
            end
        end

        function delete(app)
            if ~isempty(app.UIFigure) && isvalid(app.UIFigure)
                delete(app.UIFigure);
            end
        end
    end
end
