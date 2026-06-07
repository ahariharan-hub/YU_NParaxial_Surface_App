classdef YU_NParaxialSurface_App_V2 < matlab.apps.AppBase
    %YU_NPARAXIALSURFACE_APP_V2 Pruned V1-style lightweight system viewer.

    properties (Access = public)
        UIFigure matlab.ui.Figure
    end

    properties (Access = private)
        RootFolder string
        CoreFolder string
        WorkflowsFolder string
        PlottingFolder string

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
        TimingLabel matlab.ui.control.Label

        ObjectTypeDropdown matlab.ui.control.DropDown
        FieldModeDropdown matlab.ui.control.DropDown
        ObjectZField matlab.ui.control.NumericEditField
        DiagnosticFieldField matlab.ui.control.NumericEditField
        FieldMinYField matlab.ui.control.NumericEditField
        FieldMaxYField matlab.ui.control.NumericEditField
        FieldCountField matlab.ui.control.NumericEditField
        RayCountField matlab.ui.control.NumericEditField
        GratingWavelengthField matlab.ui.control.NumericEditField
        GratingPeriodField matlab.ui.control.NumericEditField
        GratingIncidentAngleField matlab.ui.control.NumericEditField
        GratingOrdersField matlab.ui.control.EditField
        GratingNInField matlab.ui.control.NumericEditField
        GratingNOutField matlab.ui.control.NumericEditField
        PresetDropdown matlab.ui.control.DropDown
        RayFanModeDropdown matlab.ui.control.DropDown
        ManualUMaxField matlab.ui.control.NumericEditField
        SurfaceCurvesCheckBox matlab.ui.control.CheckBox
        CardinalPointsCheckBox matlab.ui.control.CheckBox
        SystemFocalLengthCheckBox matlab.ui.control.CheckBox
        FitFocalLengthCheckBox matlab.ui.control.CheckBox
        StopPupilMarkersCheckBox matlab.ui.control.CheckBox
        ShowElementLabelsCheckBox matlab.ui.control.CheckBox
        ElementLabelStyleDropdown matlab.ui.control.DropDown
        LegendCheckBox matlab.ui.control.CheckBox

        PrescriptionTable matlab.ui.control.Table
        RayAxes matlab.ui.control.UIAxes
        MatrixTextArea matlab.ui.control.TextArea
        MatrixChainTextArea matlab.ui.control.TextArea
        MatrixChainTable matlab.ui.control.Table
        ElementTable matlab.ui.control.Table
        CardinalTextArea matlab.ui.control.TextArea
        CardinalTable matlab.ui.control.Table
        StopPupilTextArea matlab.ui.control.TextArea
        StopPupilTable matlab.ui.control.Table
        EquationsTextArea matlab.ui.control.TextArea

        Data struct
        SelectedPrescriptionRows double = []
    end

    methods (Access = private)

        function startup(app)
            app.RootFolder = string(fileparts(mfilename('fullpath')));
            app.CoreFolder = fullfile(app.RootFolder, "core");
            app.WorkflowsFolder = fullfile(app.RootFolder, "workflows");
            app.PlottingFolder = fullfile(app.RootFolder, "plotting");

            if exist(app.CoreFolder, 'dir')
                addpath(app.CoreFolder);
            else
                app.setStatus("Core helper folder was not found.", true);
                return
            end
            if exist(app.WorkflowsFolder, 'dir')
                addpath(app.WorkflowsFolder);
            end
            if exist(app.PlottingFolder, 'dir')
                addpath(app.PlottingFolder);
            else
                app.setStatus("Plotting helper folder was not found.", true);
                return
            end

            app.loadDefaults();
            app.setStatus("Edit the prescription, then press Run Trace.", false);
        end

        function createComponents(app)
            app.UIFigure = uifigure( ...
                'Name', 'Y-U N Paraxial Surface App V2', ...
                'Position', [70 70 1360 840], ...
                'Color', [0.97 0.97 0.96]);
            app.createMenus();

            app.MainGrid = uigridlayout(app.UIFigure, [1 2]);
            app.MainGrid.ColumnWidth = {360, '1x'};
            app.MainGrid.RowHeight = {'1x'};
            app.MainGrid.Padding = [10 10 10 10];
            app.MainGrid.ColumnSpacing = 10;
            app.MainGrid.Tag = 'nparaxial_v2_main_grid';

            app.LeftGrid = uigridlayout(app.MainGrid, [2 1]);
            app.LeftGrid.Layout.Row = 1;
            app.LeftGrid.Layout.Column = 1;
            app.LeftGrid.RowHeight = {136, '1x'};
            app.LeftGrid.ColumnWidth = {'1x'};
            app.LeftGrid.Padding = [0 0 0 0];
            app.LeftGrid.RowSpacing = 8;
            app.LeftGrid.Tag = 'nparaxial_v2_left_grid';

            app.ActionGrid = uigridlayout(app.LeftGrid, [4 1]);
            app.ActionGrid.Layout.Row = 1;
            app.ActionGrid.Layout.Column = 1;
            app.ActionGrid.RowHeight = {36, 32, 22, '1x'};
            app.ActionGrid.ColumnWidth = {'1x'};
            app.ActionGrid.Padding = [0 0 0 0];
            app.ActionGrid.RowSpacing = 6;

            app.RunButton = uibutton(app.ActionGrid, 'push', ...
                'Text', 'Run Trace', ...
                'FontWeight', 'bold', ...
                'Tag', 'nparaxial_v2_run_trace', ...
                'ButtonPushedFcn', @(~, ~) app.runTrace());
            app.RunButton.Layout.Row = 1;
            app.RunButton.Layout.Column = 1;

            app.ResetButton = uibutton(app.ActionGrid, 'push', ...
                'Text', 'Reset Defaults', ...
                'Tag', 'nparaxial_v2_reset_defaults', ...
                'ButtonPushedFcn', @(~, ~) app.resetDefaults());
            app.ResetButton.Layout.Row = 2;
            app.ResetButton.Layout.Column = 1;

            app.TimingLabel = uilabel(app.ActionGrid, ...
                'Text', 'Run time: --', ...
                'Tag', 'nparaxial_v2_timing_label');
            app.TimingLabel.Layout.Row = 3;
            app.TimingLabel.Layout.Column = 1;

            app.StatusLabel = uilabel(app.ActionGrid, ...
                'Text', '', ...
                'WordWrap', 'on', ...
                'FontColor', [0.2 0.42 0.2], ...
                'Tag', 'nparaxial_v2_status');
            app.StatusLabel.Layout.Row = 4;
            app.StatusLabel.Layout.Column = 1;

            app.ControlPanel = uipanel(app.LeftGrid, ...
                'Title', 'Trace Controls', ...
                'FontWeight', 'bold', ...
                'Tag', 'nparaxial_v2_trace_controls_panel');
            app.ControlPanel.Layout.Row = 2;
            app.ControlPanel.Layout.Column = 1;

            app.ControlGrid = uigridlayout(app.ControlPanel, [20 2]);
            app.ControlGrid.ColumnWidth = {'1x', 160};
            app.ControlGrid.RowHeight = {22, 26, 26, 26, 26, 26, 26, ...
                26, 26, 22, 26, 26, 26, 26, 26, 26, 58, 26, 28, '1x'};
            app.ControlGrid.Padding = [10 10 10 10];
            app.ControlGrid.RowSpacing = 4;
            app.ControlGrid.ColumnSpacing = 8;
            app.ControlGrid.Tag = 'nparaxial_v2_control_grid';

            header = uilabel(app.ControlGrid, ...
                'Text', 'Object/source', ...
                'FontWeight', 'bold');
            header.Layout.Row = 1;
            header.Layout.Column = [1 2];

            app.addControlLabel('Object type', 2);
            app.ObjectTypeDropdown = uidropdown(app.ControlGrid, ...
                'Items', {'Point object', 'Grating object'}, ...
                'Value', 'Point object', ...
                'Tag', 'nparaxial_v2_object_type', ...
                'ValueChangedFcn', @(~, ~) app.objectTypeChanged());
            app.ObjectTypeDropdown.Layout.Row = 2;
            app.ObjectTypeDropdown.Layout.Column = 2;

            app.addControlLabel('Object plane z', 3);
            app.ObjectZField = app.addNumericField(3, -120, ...
                'nparaxial_v2_object_z');

            app.addControlLabel('Field mode', 4);
            app.FieldModeDropdown = uidropdown(app.ControlGrid, ...
                'Items', {'Single field y', 'Y field sweep'}, ...
                'Value', 'Single field y', ...
                'Tag', 'nparaxial_v2_field_mode', ...
                'ValueChangedFcn', @(~, ~) app.fieldModeChanged());
            app.FieldModeDropdown.Layout.Row = 4;
            app.FieldModeDropdown.Layout.Column = 2;

            app.addControlLabel('Field y [mm]', 5);
            app.DiagnosticFieldField = app.addNumericField(5, 0, ...
                'nparaxial_v2_field_height');

            app.addControlLabel('Field min y', 6);
            app.FieldMinYField = app.addNumericField(6, -5, ...
                'nparaxial_v2_field_min_y');

            app.addControlLabel('Field max y', 7);
            app.FieldMaxYField = app.addNumericField(7, 5, ...
                'nparaxial_v2_field_max_y');

            app.addControlLabel('Field count', 8);
            app.FieldCountField = app.addNumericField(8, 3, ...
                'nparaxial_v2_field_count');
            app.FieldCountField.Limits = [1 Inf];
            app.FieldCountField.RoundFractionalValues = 'on';

            app.addControlLabel('Rays per field', 9);
            app.RayCountField = app.addNumericField(9, 9, ...
                'nparaxial_v2_ray_count');
            app.RayCountField.Limits = [3 Inf];
            app.RayCountField.RoundFractionalValues = 'on';

            gratingHeader = uilabel(app.ControlGrid, ...
                'Text', 'Grating object', ...
                'FontWeight', 'bold');
            gratingHeader.Layout.Row = 10;
            gratingHeader.Layout.Column = [1 2];

            app.addControlLabel('Wavelength [um]', 11);
            app.GratingWavelengthField = app.addNumericField(11, 0.193, ...
                'nparaxial_v2_grating_wavelength_um');
            app.GratingWavelengthField.Limits = [eps Inf];

            app.addControlLabel('Period [um]', 12);
            app.GratingPeriodField = app.addNumericField(12, 4.0, ...
                'nparaxial_v2_grating_period_um');
            app.GratingPeriodField.Limits = [eps Inf];

            app.addControlLabel('Incident angle [deg]', 13);
            app.GratingIncidentAngleField = app.addNumericField(13, 0, ...
                'nparaxial_v2_grating_incident_angle_deg');

            app.addControlLabel('Orders', 14);
            app.GratingOrdersField = uieditfield(app.ControlGrid, 'text', ...
                'Value', '-2:2', ...
                'Tag', 'nparaxial_v2_grating_orders', ...
                'ValueChangedFcn', @(~, ~) app.requestTrace());
            app.GratingOrdersField.Layout.Row = 14;
            app.GratingOrdersField.Layout.Column = 2;

            app.addControlLabel('n in', 15);
            app.GratingNInField = app.addNumericField(15, 1.0, ...
                'nparaxial_v2_grating_n_in');
            app.GratingNInField.Limits = [eps Inf];

            app.addControlLabel('n out', 16);
            app.GratingNOutField = app.addNumericField(16, 1.0, ...
                'nparaxial_v2_grating_n_out');
            app.GratingNOutField.Limits = [eps Inf];

            note = uilabel(app.ControlGrid, ...
                'Text', ['V2 is a lightweight first-order system viewer. ', ...
                'Heavy validity diagnostics, field-sweep diagnostics, exports, and ', ...
                'batch studies are available through script workflows.'], ...
                'WordWrap', 'on', ...
                'FontColor', [0.25 0.25 0.25]);
            note.Layout.Row = 17;
            note.Layout.Column = [1 2];

            app.addControlLabel('Default prescription', 18);
            app.PresetDropdown = uidropdown(app.ControlGrid, ...
                'Items', { ...
                'Single thin lens', ...
                'Two thin lenses', ...
                'Two-surface thick lens', ...
                'Stop clipping demo', ...
                'Homogeneous translation / free-space propagation'}, ...
                'Value', 'Two thin lenses', ...
                'Tag', 'nparaxial_v2_preset', ...
                'ValueChangedFcn', @(~, ~) app.requestTrace());
            app.PresetDropdown.Layout.Row = 18;
            app.PresetDropdown.Layout.Column = 2;

            presetButton = uibutton(app.ControlGrid, 'push', ...
                'Text', 'Load Default', ...
                'Tag', 'nparaxial_v2_load_default', ...
                'ButtonPushedFcn', @(~, ~) app.loadSelectedPreset());
            presetButton.Layout.Row = 19;
            presetButton.Layout.Column = [1 2];

            app.TabGroup = uitabgroup(app.MainGrid, ...
                'Tag', 'nparaxial_v2_tab_group', ...
                'SelectionChangedFcn', @(~, ~) app.refreshSelectedTab());
            app.TabGroup.Layout.Row = 1;
            app.TabGroup.Layout.Column = 2;

            app.createRayDiagramTab();
            app.createSystemMatrixTab();
            app.createCardinalTab();
            app.createStopPupilTab();
            app.createEquationsTab();
        end

        function createMenus(app)
            fileMenu = uimenu(app.UIFigure, 'Text', 'File');
            uimenu(fileMenu, 'Text', 'Run Trace', ...
                'MenuSelectedFcn', @(~, ~) app.runTrace());
            uimenu(fileMenu, 'Text', 'Reset Defaults', ...
                'MenuSelectedFcn', @(~, ~) app.resetDefaults());
            uimenu(fileMenu, ...
                'Text', 'Load prescription CSV', ...
                'Separator', 'on', ...
                'MenuSelectedFcn', @(~, ~) app.loadPrescriptionCsvDialog());
            uimenu(fileMenu, 'Text', 'Save prescription CSV', ...
                'MenuSelectedFcn', @(~, ~) app.savePrescriptionCsvDialog());
            uimenu(fileMenu, ...
                'Text', 'Load prescription MAT', ...
                'Separator', 'on', ...
                'MenuSelectedFcn', @(~, ~) app.loadPrescriptionMatDialog());
            uimenu(fileMenu, 'Text', 'Save prescription MAT', ...
                'MenuSelectedFcn', @(~, ~) app.savePrescriptionMatDialog());

            viewMenu = uimenu(app.UIFigure, 'Text', 'View');
            for title = ["Ray Diagram", "System Matrix", ...
                    "Cardinal/Gaussian", "Stop/Pupils", "Equations"]
                uimenu(viewMenu, 'Text', "Show " + title, ...
                    'MenuSelectedFcn', @(~, ~) app.selectTabByTitle(title));
            end
        end

        function createRayDiagramTab(app)
            rayTab = uitab(app.TabGroup, 'Title', 'Ray Diagram');
            rayGrid = uigridlayout(rayTab, [2 1]);
            rayGrid.RowHeight = {410, '1x'};
            rayGrid.ColumnWidth = {'1x'};
            rayGrid.Padding = [8 8 8 8];
            rayGrid.RowSpacing = 8;
            rayGrid.Tag = 'nparaxial_v2_ray_grid';

            rayTopGrid = uigridlayout(rayGrid, [1 2]);
            rayTopGrid.Layout.Row = 1;
            rayTopGrid.Layout.Column = 1;
            rayTopGrid.ColumnWidth = {455, '1x'};
            rayTopGrid.RowHeight = {'1x'};
            rayTopGrid.Padding = [0 0 0 0];
            rayTopGrid.ColumnSpacing = 8;
            rayTopGrid.Tag = 'nparaxial_v2_ray_top_grid';

            controlsPanel = uipanel(rayTopGrid, ...
                'Title', 'Ray Fan / Prescription Controls', ...
                'FontWeight', 'bold', ...
                'Tag', 'nparaxial_v2_ray_fan_prescription_panel');
            controlsPanel.Layout.Row = 1;
            controlsPanel.Layout.Column = 1;

            app.PrescriptionButtonGrid = uigridlayout(controlsPanel, [12 2]);
            app.PrescriptionButtonGrid.RowHeight = ...
                {24, 24, 20, 24, 24, 24, 24, 22, 26, 26, 26, 26};
            app.PrescriptionButtonGrid.ColumnWidth = {165, '1x'};
            app.PrescriptionButtonGrid.Padding = [8 8 8 8];
            app.PrescriptionButtonGrid.RowSpacing = 4;
            app.PrescriptionButtonGrid.ColumnSpacing = 6;
            app.PrescriptionButtonGrid.Tag = ...
                'nparaxial_v2_prescription_button_grid';

            rayFanLabel = uilabel(app.PrescriptionButtonGrid, ...
                'Text', 'Ray fan mode', ...
                'HorizontalAlignment', 'left');
            rayFanLabel.Layout.Row = 1;
            rayFanLabel.Layout.Column = 1;
            app.RayFanModeDropdown = uidropdown(app.PrescriptionButtonGrid, ...
                'Items', {'Manual fixed-angle fan', ...
                'Aperture-limited admitted cone'}, ...
                'Value', 'Manual fixed-angle fan', ...
                'Tag', 'nparaxial_v2_fan_mode', ...
                'ValueChangedFcn', @(~, ~) app.requestTrace());
            app.RayFanModeDropdown.Layout.Row = 1;
            app.RayFanModeDropdown.Layout.Column = 2;

            manualUMaxLabel = uilabel(app.PrescriptionButtonGrid, ...
                'Text', 'Manual u max', ...
                'HorizontalAlignment', 'left');
            manualUMaxLabel.Layout.Row = 2;
            manualUMaxLabel.Layout.Column = 1;
            app.ManualUMaxField = uieditfield(app.PrescriptionButtonGrid, ...
                'numeric', ...
                'Value', 0.04, ...
                'Limits', [eps Inf], ...
                'Tag', 'nparaxial_v2_manual_u_max', ...
                'ValueChangedFcn', @(~, ~) app.requestTrace());
            app.ManualUMaxField.Layout.Row = 2;
            app.ManualUMaxField.Layout.Column = 2;

            overlayLabel = uilabel(app.PrescriptionButtonGrid, ...
                'Text', 'Graphics overlays', ...
                'FontWeight', 'bold');
            overlayLabel.Layout.Row = 3;
            overlayLabel.Layout.Column = [1 2];

            app.SurfaceCurvesCheckBox = uicheckbox(app.PrescriptionButtonGrid, ...
                'Text', 'Surface curves', ...
                'Value', true, ...
                'Tag', 'nparaxial_v2_show_surface_curves', ...
                'ValueChangedFcn', @(~, ~) app.refreshRayDiagramDisplay());
            app.SurfaceCurvesCheckBox.Layout.Row = 4;
            app.SurfaceCurvesCheckBox.Layout.Column = 1;

            app.CardinalPointsCheckBox = uicheckbox(app.PrescriptionButtonGrid, ...
                'Text', 'Show cardinal points', ...
                'Value', false, ...
                'Tag', 'nparaxial_v2_show_cardinal_markers', ...
                'ValueChangedFcn', @(~, ~) app.refreshRayDiagramDisplay());
            app.CardinalPointsCheckBox.Layout.Row = 4;
            app.CardinalPointsCheckBox.Layout.Column = 2;

            app.StopPupilMarkersCheckBox = uicheckbox(app.PrescriptionButtonGrid, ...
                'Text', 'Show stop/pupil markers', ...
                'Value', true, ...
                'Tag', 'nparaxial_v2_show_stop_pupil_markers', ...
                'ValueChangedFcn', @(~, ~) app.refreshRayDiagramDisplay());
            app.StopPupilMarkersCheckBox.Layout.Row = 5;
            app.StopPupilMarkersCheckBox.Layout.Column = 1;

            app.LegendCheckBox = uicheckbox(app.PrescriptionButtonGrid, ...
                'Text', 'Show legend', ...
                'Value', true, ...
                'Tag', 'nparaxial_v2_show_legend', ...
                'ValueChangedFcn', @(~, ~) app.refreshRayDiagramDisplay());
            app.LegendCheckBox.Layout.Row = 5;
            app.LegendCheckBox.Layout.Column = 2;

            app.SystemFocalLengthCheckBox = uicheckbox(app.PrescriptionButtonGrid, ...
                'Text', 'Show system focal length', ...
                'Value', false, ...
                'Tag', 'nparaxial_v2_show_system_focal_length', ...
                'ValueChangedFcn', @(~, ~) app.refreshRayDiagramDisplay());
            app.SystemFocalLengthCheckBox.Layout.Row = 6;
            app.SystemFocalLengthCheckBox.Layout.Column = 1;

            app.FitFocalLengthCheckBox = uicheckbox(app.PrescriptionButtonGrid, ...
                'Text', 'Fit focal view', ...
                'Value', false, ...
                'Tag', 'nparaxial_v2_fit_focal_length', ...
                'ValueChangedFcn', @(~, ~) app.refreshRayDiagramDisplay());
            app.FitFocalLengthCheckBox.Layout.Row = 6;
            app.FitFocalLengthCheckBox.Layout.Column = 2;

            app.ShowElementLabelsCheckBox = uicheckbox( ...
                app.PrescriptionButtonGrid, ...
                'Text', 'Show element labels', ...
                'Value', true, ...
                'Tag', 'nparaxial_v2_show_element_labels', ...
                'ValueChangedFcn', @(~, ~) app.elementLabelControlChanged());
            app.ShowElementLabelsCheckBox.Layout.Row = 7;
            app.ShowElementLabelsCheckBox.Layout.Column = 1;

            app.ElementLabelStyleDropdown = uidropdown( ...
                app.PrescriptionButtonGrid, ...
                'Items', {'Compact', 'Detailed', 'Off'}, ...
                'Value', 'Compact', ...
                'Tag', 'nparaxial_v2_element_label_style', ...
                'ValueChangedFcn', @(~, ~) app.refreshRayDiagramDisplay());
            app.ElementLabelStyleDropdown.Layout.Row = 7;
            app.ElementLabelStyleDropdown.Layout.Column = 2;

            app.addPrescriptionButton('Add Thin Lens', 9, 1, ...
                @(~, ~) app.addPrescriptionRow("thinlens"));
            app.addPrescriptionButton('Add Surface', 9, 2, ...
                @(~, ~) app.addPrescriptionRow("surface"));
            app.addPrescriptionButton('Add Stop', 10, 1, ...
                @(~, ~) app.addPrescriptionRow("stop"));
            app.addPrescriptionButton('Add Dummy', 10, 2, ...
                @(~, ~) app.addPrescriptionRow("dummy"));
            app.addPrescriptionButton('Duplicate Row', 11, 1, ...
                @(~, ~) app.duplicatePrescriptionRow());
            app.addPrescriptionButton('Delete Selected Row', 11, 2, ...
                @(~, ~) app.deleteSelectedPrescriptionRows());
            app.addPrescriptionButton('Sort Prescription', 12, 1, ...
                @(~, ~) app.sortPrescriptionTable());
            app.addPrescriptionButton('Check Prescription', 12, 2, ...
                @(~, ~) app.checkPrescription());

            app.PrescriptionTable = uitable(rayTopGrid);
            app.PrescriptionTable.Layout.Row = 1;
            app.PrescriptionTable.Layout.Column = 2;
            app.PrescriptionTable.ColumnEditable = true(1, 10);
            app.PrescriptionTable.Tag = 'nparaxial_v2_prescription_table';
            app.PrescriptionTable.CellEditCallback = @(~, ~) app.requestTrace();
            app.PrescriptionTable.CellSelectionCallback = ...
                @(~, event) app.selectPrescriptionRows(event);

            app.RayAxes = uiaxes(rayGrid);
            app.RayAxes.Layout.Row = 2;
            app.RayAxes.Layout.Column = 1;
            app.RayAxes.Tag = 'nparaxial_v2_ray_axes';
        end

        function createSystemMatrixTab(app)
            matrixTab = uitab(app.TabGroup, 'Title', 'System Matrix');
            matrixGrid = uigridlayout(matrixTab, [5 1]);
            matrixGrid.RowHeight = {88, 88, 22, '1x', 120};
            matrixGrid.Padding = [8 8 8 8];
            matrixGrid.RowSpacing = 8;

            app.MatrixTextArea = uitextarea(matrixGrid, ...
                'Editable', 'off', ...
                'FontName', 'Consolas', ...
                'Tag', 'nparaxial_v2_matrix_text');
            if isprop(app.MatrixTextArea, 'WordWrap')
                app.MatrixTextArea.WordWrap = 'off';
            end
            app.MatrixTextArea.Layout.Row = 1;

            app.MatrixChainTextArea = uitextarea(matrixGrid, ...
                'Editable', 'off', ...
                'FontName', 'Consolas', ...
                'Tag', 'nparaxial_v2_matrix_chain_text');
            if isprop(app.MatrixChainTextArea, 'WordWrap')
                app.MatrixChainTextArea.WordWrap = 'off';
            end
            app.MatrixChainTextArea.Layout.Row = 2;

            chainLabel = uilabel(matrixGrid, ...
                'Text', 'Matrix chain steps', ...
                'FontWeight', 'bold');
            chainLabel.Layout.Row = 3;

            app.MatrixChainTable = uitable(matrixGrid, ...
                'Tag', 'nparaxial_v2_matrix_chain_table');
            app.MatrixChainTable.Layout.Row = 4;

            app.ElementTable = uitable(matrixGrid, ...
                'Tag', 'nparaxial_v2_element_table');
            app.ElementTable.Layout.Row = 5;
        end

        function createCardinalTab(app)
            cardinalTab = uitab(app.TabGroup, 'Title', 'Cardinal/Gaussian');
            cardinalGrid = uigridlayout(cardinalTab, [2 1]);
            cardinalGrid.RowHeight = {150, '1x'};
            cardinalGrid.Padding = [8 8 8 8];
            cardinalGrid.RowSpacing = 8;

            app.CardinalTextArea = uitextarea(cardinalGrid, ...
                'Editable', 'off', ...
                'FontName', 'Consolas', ...
                'Tag', 'nparaxial_v2_cardinal_text');
            app.CardinalTextArea.Layout.Row = 1;
            app.CardinalTable = uitable(cardinalGrid, ...
                'Tag', 'nparaxial_v2_cardinal_table');
            app.CardinalTable.Layout.Row = 2;
        end

        function createStopPupilTab(app)
            stopTab = uitab(app.TabGroup, 'Title', 'Stop/Pupils');
            stopGrid = uigridlayout(stopTab, [2 1]);
            stopGrid.RowHeight = {140, '1x'};
            stopGrid.Padding = [8 8 8 8];
            stopGrid.RowSpacing = 8;

            app.StopPupilTextArea = uitextarea(stopGrid, ...
                'Editable', 'off', ...
                'FontName', 'Consolas', ...
                'Tag', 'nparaxial_v2_stop_pupil_text');
            app.StopPupilTextArea.Layout.Row = 1;
            app.StopPupilTable = uitable(stopGrid, ...
                'Tag', 'nparaxial_v2_stop_pupil_table');
            app.StopPupilTable.Layout.Row = 2;
        end

        function createEquationsTab(app)
            equationsTab = uitab(app.TabGroup, 'Title', 'Equations');
            equationsGrid = uigridlayout(equationsTab, [1 1]);
            equationsGrid.Padding = [8 8 8 8];
            app.EquationsTextArea = uitextarea(equationsGrid, ...
                'Editable', 'off', ...
                'FontName', 'Consolas', ...
                'Value', app.equationLines(), ...
                'Tag', 'nparaxial_v2_equations_text');
            if isprop(app.EquationsTextArea, 'WordWrap')
                app.EquationsTextArea.WordWrap = 'off';
            end
        end

        function addControlLabel(app, text, row)
            label = uilabel(app.ControlGrid, ...
                'Text', text, ...
                'HorizontalAlignment', 'left');
            label.Layout.Row = row;
            label.Layout.Column = 1;
        end

        function field = addNumericField(app, row, value, tag)
            field = uieditfield(app.ControlGrid, ...
                'numeric', ...
                'Value', value, ...
                'Tag', tag, ...
                'ValueChangedFcn', @(~, ~) app.requestTrace());
            field.Layout.Row = row;
            field.Layout.Column = 2;
        end

        function button = addPrescriptionButton(app, text, row, column, ...
                callback, tag)
            button = uibutton(app.PrescriptionButtonGrid, 'push', ...
                'Text', text, ...
                'ButtonPushedFcn', callback);
            if nargin >= 6 && strlength(string(tag)) > 0
                button.Tag = char(string(tag));
            end
            button.Layout.Row = row;
            button.Layout.Column = column;
        end

        function loadDefaults(app)
            app.ObjectTypeDropdown.Value = 'Point object';
            app.FieldModeDropdown.Value = 'Single field y';
            app.ObjectZField.Value = -120;
            app.DiagnosticFieldField.Value = 0;
            app.FieldMinYField.Value = -5;
            app.FieldMaxYField.Value = 5;
            app.FieldCountField.Value = 3;
            app.RayCountField.Value = 9;
            app.GratingWavelengthField.Value = 0.193;
            app.GratingPeriodField.Value = 4.0;
            app.GratingIncidentAngleField.Value = 0;
            app.GratingOrdersField.Value = '-2:2';
            app.GratingNInField.Value = 1.0;
            app.GratingNOutField.Value = 1.0;
            app.RayFanModeDropdown.Value = 'Manual fixed-angle fan';
            app.ManualUMaxField.Value = 0.04;
            app.ShowElementLabelsCheckBox.Value = true;
            app.ElementLabelStyleDropdown.Value = 'Compact';
            app.PresetDropdown.Value = 'Two thin lenses';
            app.PrescriptionTable.Data = nparaxial_default_prescription_yu();
            app.SelectedPrescriptionRows = [];
            app.Data = struct();
            app.updateObjectModeControls();
            app.updateFieldModeControls();
            app.updateElementLabelControls();
            app.clearDisplays('Run Trace to refresh V2 system view.');
            app.TimingLabel.Text = 'Run time: --';
        end

        function fieldModeChanged(app)
            app.updateFieldModeControls();
            app.requestTrace();
        end

        function objectTypeChanged(app)
            app.updateObjectModeControls();
            app.requestTrace();
        end

        function updateObjectModeControls(app)
            if isempty(app.ObjectTypeDropdown) || ~isvalid(app.ObjectTypeDropdown)
                return
            end
            isGrating = string(app.ObjectTypeDropdown.Value) == "Grating object";
            if isGrating
                pointState = 'off';
                gratingState = 'on';
            else
                pointState = 'on';
                gratingState = 'off';
            end
            app.RayCountField.Enable = pointState;
            app.RayFanModeDropdown.Enable = pointState;
            app.ManualUMaxField.Enable = pointState;
            app.GratingWavelengthField.Enable = gratingState;
            app.GratingPeriodField.Enable = gratingState;
            app.GratingIncidentAngleField.Enable = gratingState;
            app.GratingOrdersField.Enable = gratingState;
            app.GratingNInField.Enable = gratingState;
            app.GratingNOutField.Enable = gratingState;
        end

        function updateFieldModeControls(app)
            if isempty(app.FieldModeDropdown) || ~isvalid(app.FieldModeDropdown)
                return
            end
            isSweep = string(app.FieldModeDropdown.Value) == "Y field sweep";
            if isSweep
                singleState = 'off';
                sweepState = 'on';
            else
                singleState = 'on';
                sweepState = 'off';
            end
            app.DiagnosticFieldField.Enable = singleState;
            app.FieldMinYField.Enable = sweepState;
            app.FieldMaxYField.Enable = sweepState;
            app.FieldCountField.Enable = sweepState;
        end

        function elementLabelControlChanged(app)
            app.updateElementLabelControls();
            app.refreshRayDiagramDisplay();
        end

        function updateElementLabelControls(app)
            if isempty(app.ElementLabelStyleDropdown) || ...
                    ~isvalid(app.ElementLabelStyleDropdown)
                return
            end
            if isempty(app.ShowElementLabelsCheckBox) || ...
                    ~isvalid(app.ShowElementLabelsCheckBox) || ...
                    app.ShowElementLabelsCheckBox.Value
                app.ElementLabelStyleDropdown.Enable = 'on';
            else
                app.ElementLabelStyleDropdown.Enable = 'off';
            end
        end

        function resetDefaults(app)
            app.loadDefaults();
            app.setStatus("Defaults loaded. Run Trace to refresh V2.", false);
        end

        function loadSelectedPreset(app)
            try
                prescription = nparaxial_default_prescription_yu( ...
                    app.PresetDropdown.Value);
                app.PrescriptionTable.Data = table_to_prescription_yu(prescription);
                app.FieldModeDropdown.Value = 'Single field y';
                app.updateFieldModeControls();
                if string(app.PresetDropdown.Value) == ...
                        "Homogeneous translation / free-space propagation"
                    app.ObjectZField.Value = 0;
                    app.DiagnosticFieldField.Value = 1;
                else
                    app.ObjectZField.Value = -120;
                    app.DiagnosticFieldField.Value = 0;
                end
                app.SelectedPrescriptionRows = [];
                app.Data = struct();
                app.clearDisplays('Preset loaded. Run Trace to refresh V2.');
                app.setStatus("Loaded default prescription: " + ...
                    string(app.PresetDropdown.Value) + ".", false);
            catch ME
                app.setStatus("Load default error: " + string(ME.message), true);
            end
        end

        function loadPrescriptionCsvDialog(app)
            try
                filename = app.promptOpenFilename( ...
                    {'*.csv', 'CSV prescription (*.csv)'}, ...
                    'Load prescription CSV');
                if strlength(filename) == 0
                    app.setStatus("Load prescription CSV canceled.", false);
                    return
                end
                app.loadPrescriptionCsv(filename);
            catch ME
                app.setStatus("Load prescription CSV error: " + ...
                    string(ME.message), true);
            end
        end

        function savePrescriptionCsvDialog(app)
            try
                filename = app.promptSaveFilename( ...
                    {'*.csv', 'CSV prescription (*.csv)'}, ...
                    'Save prescription CSV', 'prescription.csv');
                if strlength(filename) == 0
                    app.setStatus("Save prescription CSV canceled.", false);
                    return
                end
                app.savePrescriptionCsv(filename);
            catch ME
                app.setStatus("Save prescription CSV error: " + ...
                    string(ME.message), true);
            end
        end

        function loadPrescriptionMatDialog(app)
            try
                filename = app.promptOpenFilename( ...
                    {'*.mat', 'MAT prescription (*.mat)'}, ...
                    'Load prescription MAT');
                if strlength(filename) == 0
                    app.setStatus("Load prescription MAT canceled.", false);
                    return
                end
                app.loadPrescriptionMat(filename);
            catch ME
                app.setStatus("Load prescription MAT error: " + ...
                    string(ME.message), true);
            end
        end

        function savePrescriptionMatDialog(app)
            try
                filename = app.promptSaveFilename( ...
                    {'*.mat', 'MAT prescription (*.mat)'}, ...
                    'Save prescription MAT', 'prescription.mat');
                if strlength(filename) == 0
                    app.setStatus("Save prescription MAT canceled.", false);
                    return
                end
                app.savePrescriptionMat(filename);
            catch ME
                app.setStatus("Save prescription MAT error: " + ...
                    string(ME.message), true);
            end
        end

        function filename = promptOpenFilename(~, filterSpec, titleText)
            [file, path] = uigetfile(filterSpec, titleText);
            if isequal(file, 0)
                filename = "";
            else
                filename = string(fullfile(path, file));
            end
        end

        function filename = promptSaveFilename(~, filterSpec, titleText, ...
                defaultName)
            [file, path] = uiputfile(filterSpec, titleText, defaultName);
            if isequal(file, 0)
                filename = "";
            else
                filename = string(fullfile(path, file));
            end
        end

        function checkPrescription(app)
            try
                prescription = table_to_prescription_yu(app.PrescriptionTable.Data);
                prescription = nparaxial_validate_prescription_yu(prescription);
                app.PrescriptionTable.Data = prescription;
                app.Data = struct();
                app.clearDisplays('Prescription checked. Run Trace to refresh V2.');
                app.setStatus(sprintf('Prescription OK: %d enabled element(s).', ...
                    sum(prescription.enabled)), false);
            catch ME
                app.setStatus("Prescription error: " + string(ME.message), true);
            end
        end

        function prescription = validatedPrescriptionFromTable(app)
            prescription = nparaxial_validate_prescription_yu( ...
                app.PrescriptionTable.Data);
            app.PrescriptionTable.Data = table_to_prescription_yu( ...
                prescription);
        end

        function applyLoadedPrescription(app, prescription, message)
            prescription = nparaxial_validate_prescription_yu(prescription);
            app.PrescriptionTable.Data = table_to_prescription_yu( ...
                prescription);
            app.SelectedPrescriptionRows = [];
            app.Data = struct();
            app.clearDisplays(message);
        end

        function requestTrace(app)
            app.Data = struct();
            app.clearDisplays('Inputs changed. Run Trace to refresh V2.');
            app.setStatus("Inputs changed. Run Trace to refresh V2.", false);
        end

        function runTrace(app)
            try
                app.setStatus("Running lightweight V2 trace...", false);
                drawnow limitrate
                tRun = tic;
                prescription = nparaxial_validate_prescription_yu( ...
                    app.PrescriptionTable.Data);
                raySettings = app.readRaySettings();
                opts = struct( ...
                    'computeValidity', false, ...
                    'computeCardinal', true, ...
                    'computePupilStop', true, ...
                    'timingEnabled', true, ...
                    'tol', 1e-12);
                if raySettings.object_type == "Grating object"
                    data = app.runGratingTrace(prescription, raySettings, opts);
                else
                    data = nparaxial_run_trace_workflow_yu( ...
                        prescription, raySettings, opts);
                    data.object_type = "Point object";
                    data.gratingInfo = [];
                end
                data = app.annotateTraceFieldsV2(data);
                data.run_trace_elapsed_s = toc(tRun);
                data.enabledElements = nparaxial_enabled_elements_yu( ...
                    data.prescription);
                data.matrixOverview = app.matrixOverviewTable(data);
                app.Data = data;
                app.PrescriptionTable.Data = data.prescription;
                app.TimingLabel.Text = sprintf( ...
                    'Run time: %.4g s', data.run_trace_elapsed_s);
                app.refreshSelectedTab();
                if raySettings.object_type == "Grating object"
                    if data.gratingInfo.n_propagating == 0
                        app.setStatus( ...
                            "No propagating grating orders for current wavelength/period/order settings.", ...
                            true);
                    else
                        app.setStatus(sprintf( ...
                            'Grating object traced: %d field(s), %d propagating orders, %d non-propagating.', ...
                            numel(raySettings.field_heights), ...
                            data.gratingInfo.n_propagating, ...
                            data.gratingInfo.n_nonpropagating), false);
                    end
                else
                    app.setStatus(sprintf( ...
                        'V2 lightweight trace complete: %d field(s). Image: %s', ...
                        numel(raySettings.field_heights), ...
                        char(string(data.image.type))), false);
                end
            catch ME
                app.Data = struct();
                app.clearDisplays('Trace failed.');
                app.setStatus("V2 trace error: " + string(ME.message), true);
            end
        end

        function data = runGratingTrace(app, prescription, raySettings, opts)
            tol = opts.tol;
            img = nparaxial_solve_image_plane_yu( ...
                prescription, raySettings.z_obj, tol);
            zTrace = img.trace_z_final;
            if ~isscalar(zTrace) || ~isfinite(zTrace) || ...
                    zTrace < raySettings.z_obj
                error('Grating trace z_final must be finite and after z_obj.');
            end

            matrixChain = nparaxial_matrix_chain_yu( ...
                prescription, raySettings.z_obj, zTrace);
            fieldHeights = raySettings.field_heights(:);
            bundleSet = struct([]);
            gratingInfo = [];
            tracedRayCount = 0;
            for k = 1:numel(fieldHeights)
                yField = fieldHeights(k);
                [rays, infoK] = nparaxial_make_grating_order_rays_yu( ...
                    raySettings.z_obj, yField, ...
                    raySettings.wavelength_um, ...
                    raySettings.grating_period_um, ...
                    raySettings.diffraction_orders, ...
                    raySettings.incident_angle_deg, ...
                    raySettings.n_in, raySettings.n_out);
                rays = app.addRayFieldMetadata(rays, k, yField);
                if height(rays) > 0
                    rays.name = "field_" + string(k) + "_" + rays.name;
                    rays.ray_name = rays.name;
                    bundle = nparaxial_trace_bundle_yu( ...
                        rays, prescription, zTrace);
                else
                    bundle = app.emptyTraceBundleV2();
                end

                if k == 1
                    gratingInfo = infoK;
                end
                tracedRayCount = tracedRayCount + height(rays);
                bundleSet(k).field_index = k; %#ok<AGROW>
                bundleSet(k).y_obj = yField; %#ok<AGROW>
                bundleSet(k).y_field = yField; %#ok<AGROW>
                bundleSet(k).rays = rays; %#ok<AGROW>
                bundleSet(k).bundle = bundle; %#ok<AGROW>
                bundleSet(k).ray_fan_info = struct( ...
                    'mode', "Grating object", ...
                    'status_text', string(infoK.status_text)); %#ok<AGROW>
            end

            if isempty(gratingInfo)
                gratingInfo = struct( ...
                    'order_table', table(), ...
                    'n_propagating', 0, ...
                    'n_nonpropagating', 0, ...
                    'status_text', 'No grating fields were selected.');
            end
            gratingInfo.field_heights = fieldHeights;
            gratingInfo.n_fields = numel(fieldHeights);
            gratingInfo.n_traced_rays = tracedRayCount;
            if isfield(gratingInfo, 'order_table') && ...
                    istable(gratingInfo.order_table) && ...
                    ismember("is_propagating", ...
                    string(gratingInfo.order_table.Properties.VariableNames))
                gratingInfo.propagating_orders = ...
                    gratingInfo.order_table.diffraction_order( ...
                    gratingInfo.order_table.is_propagating);
            else
                gratingInfo.propagating_orders = [];
            end

            elements = nparaxial_enabled_elements_yu(prescription);
            cardinal = [];
            cardinalError = "";
            try
                cardinal = nparaxial_cardinal_points_yu( ...
                    prescription, elements.z(1), elements.z(end), tol);
            catch ME
                cardinalError = string(ME.message);
            end

            stopPupil = [];
            stopPupilError = "";
            try
                stopPupil = app.computeStopPupilV2( ...
                    prescription, raySettings.z_obj, tol);
            catch ME
                stopPupilError = string(ME.message);
            end

            data = struct();
            data.prescription = prescription;
            data.raySettings = raySettings;
            data.opts = opts;
            data.rays = firstBundleSetValueLocal(bundleSet, "rays", table());
            data.bundle = firstBundleSetValueLocal( ...
                bundleSet, "bundle", app.emptyTraceBundleV2());
            data.bundleSet = bundleSet;
            data.rayFanInfo = [bundleSet.ray_fan_info].';
            data.eventSequence = nparaxial_event_sequence_yu(prescription);
            data.systemMatrix = img.M_ref;
            data.traceMatrix = matrixChain.final_matrix;
            data.matrixChain = matrixChain;
            data.image = img;
            data.trace_z_final = zTrace;
            data.cardinal = cardinal;
            data.cardinal_error = cardinalError;
            data.stopPupil = stopPupil;
            data.stop_pupil_error = stopPupilError;
            data.validity = [];
            data.validity_error = "";
            data.performance_timer = [];
            data.performance_log = table();
            data.timing = strings(0, 1);
            data.status = string(gratingInfo.status_text);
            data.object_type = "Grating object";
            data.gratingInfo = gratingInfo;
        end

        function stopPupil = computeStopPupilV2(~, prescription, zObj, tol)
            elements = nparaxial_enabled_elements_yu(prescription);
            stopPupil = struct();
            stopPupil.stop = nparaxial_select_aperture_stop_yu( ...
                prescription, zObj, 0, tol);
            stopPupil.pupil = [];
            if ~isempty(stopPupil.stop) && stopPupil.stop.has_stop
                stopPupil.pupil = nparaxial_pupil_diagnostics_yu( ...
                    prescription, elements.z(1), elements.z(end), ...
                    stopPupil.stop.selected_event_index, tol);
            end
        end

        function bundle = emptyTraceBundleV2(~)
            bundle = struct( ...
                'name', {}, ...
                'ray_in', {}, ...
                'res', {}, ...
                'trc', {}, ...
                'yf', {}, ...
                'uf', {});
        end

        function raySettings = readRaySettings(app)
            nRays = round(app.RayCountField.Value);
            if nRays < 3
                nRays = 3;
            end
            if mod(nRays, 2) == 0
                nRays = nRays + 1;
            end
            app.RayCountField.Value = nRays;

            raySettings = struct();
            raySettings.object_type = string(app.ObjectTypeDropdown.Value);
            raySettings.z_obj = app.ObjectZField.Value;
            raySettings.field_mode = string(app.FieldModeDropdown.Value);
            raySettings.field_heights = app.readFieldHeights();
            raySettings.field_height = raySettings.field_heights(1);
            raySettings.n_rays = nRays;
            raySettings.fan_mode = string(app.RayFanModeDropdown.Value);
            raySettings.u_max = app.ManualUMaxField.Value;
            raySettings.wavelength_um = app.GratingWavelengthField.Value;
            raySettings.grating_period_um = app.GratingPeriodField.Value;
            raySettings.incident_angle_deg = ...
                app.GratingIncidentAngleField.Value;
            raySettings.diffraction_orders = app.parseDiffractionOrders( ...
                app.GratingOrdersField.Value);
            raySettings.n_in = app.GratingNInField.Value;
            raySettings.n_out = app.GratingNOutField.Value;
        end

        function fieldHeights = readFieldHeights(app)
            if string(app.FieldModeDropdown.Value) == "Y field sweep"
                nFields = round(app.FieldCountField.Value);
                if ~isscalar(nFields) || ~isfinite(nFields) || nFields < 1
                    nFields = 1;
                end
                app.FieldCountField.Value = nFields;
                fieldMin = app.FieldMinYField.Value;
                fieldMax = app.FieldMaxYField.Value;
                if ~isfinite(fieldMin) || ~isfinite(fieldMax)
                    error('Field min y and Field max y must be finite.');
                end
                if nFields == 1
                    fieldHeights = mean([fieldMin, fieldMax]);
                else
                    fieldHeights = linspace(fieldMin, fieldMax, nFields).';
                end
            else
                fieldY = app.DiagnosticFieldField.Value;
                if ~isfinite(fieldY)
                    error('Field y [mm] must be finite.');
                end
                fieldHeights = fieldY;
            end
            fieldHeights = double(fieldHeights(:));
            if isempty(fieldHeights) || any(~isfinite(fieldHeights))
                error('Selected y-field heights must be finite.');
            end
        end

        function data = annotateTraceFieldsV2(app, data)
            if ~isfield(data, 'bundleSet') || isempty(data.bundleSet)
                return
            end
            for q = 1:numel(data.bundleSet)
                yField = NaN;
                if isfield(data.bundleSet(q), 'y_field') && ...
                        ~isempty(data.bundleSet(q).y_field)
                    yField = data.bundleSet(q).y_field;
                elseif isfield(data.bundleSet(q), 'y_obj') && ...
                        ~isempty(data.bundleSet(q).y_obj)
                    yField = data.bundleSet(q).y_obj;
                elseif isfield(data, 'raySettings') && ...
                        isfield(data.raySettings, 'field_heights') && ...
                        numel(data.raySettings.field_heights) >= q
                    yField = data.raySettings.field_heights(q);
                end
                data.bundleSet(q).field_index = q;
                data.bundleSet(q).y_obj = yField;
                data.bundleSet(q).y_field = yField;
                if isfield(data.bundleSet(q), 'rays') && ...
                        istable(data.bundleSet(q).rays)
                    data.bundleSet(q).rays = app.addRayFieldMetadata( ...
                        data.bundleSet(q).rays, q, yField);
                end
            end
            data.rays = firstBundleSetValueLocal(data.bundleSet, ...
                "rays", table());
            data.bundle = firstBundleSetValueLocal(data.bundleSet, ...
                "bundle", app.emptyTraceBundleV2());
        end

        function rays = addRayFieldMetadata(~, rays, fieldIndex, yField)
            if ~istable(rays)
                return
            end
            nRows = height(rays);
            rays.field_index = repmat(double(fieldIndex), nRows, 1);
            rays.y_field = repmat(double(yField), nRows, 1);
        end

        function orders = parseDiffractionOrders(~, value)
            text = strtrim(char(string(value)));
            if isempty(text)
                error('Diffraction orders must not be empty.');
            end
            clean = regexprep(text, '[\[\]\(\)]', ' ');
            if contains(clean, ':')
                rangeText = regexprep(clean, '\s+', '');
                parts = strsplit(rangeText, ':');
                if numel(parts) ~= 2 && numel(parts) ~= 3
                    error('Order range must use start:stop or start:step:stop.');
                end
                nums = str2double(parts);
                if any(~isfinite(nums))
                    error('Order range contains a nonnumeric value.');
                end
                if numel(nums) == 2
                    if nums(1) <= nums(2)
                        step = 1;
                    else
                        step = -1;
                    end
                    orders = (nums(1):step:nums(2)).';
                else
                    if nums(2) == 0
                        error('Order range step must be nonzero.');
                    end
                    orders = (nums(1):nums(2):nums(3)).';
                end
            else
                clean = regexprep(clean, '[,;]', ' ');
                parts = regexp(strtrim(clean), '\s+', 'split');
                orders = str2double(parts(:));
            end

            orders = double(orders(:));
            orders = orders(isfinite(orders));
            if isempty(orders)
                error('Diffraction orders must contain at least one integer.');
            end
            if any(abs(orders - round(orders)) > eps)
                error('Diffraction orders must be integers.');
            end
            orders = unique(round(orders), 'sorted');
        end

        function refreshSelectedTab(app)
            if isempty(app.Data) || isempty(fieldnames(app.Data))
                return
            end
            switch string(app.TabGroup.SelectedTab.Title)
                case "Ray Diagram"
                    app.plotRayDiagram();
                case "System Matrix"
                    app.updateSystemMatrix();
                case "Cardinal/Gaussian"
                    app.updateCardinal();
                case "Stop/Pupils"
                    app.updateStopPupils();
                case "Equations"
                    app.EquationsTextArea.Value = app.equationLines();
            end
        end

        function clearRayDiagramAxesV2(app)
            ax = app.RayAxes;
            if isempty(ax) || ~isvalid(ax)
                return
            end

            try
                legend(ax, 'off');
            catch
            end

            try
                nparaxial_clear_cardinal_points_yu(ax);
            catch
            end

            hChildren = allchild(ax);
            if ~isempty(hChildren)
                delete(hChildren(isgraphics(hChildren)));
            end

            hTagged = findall(ax, 'Tag', 'nparaxial_cardinal_overlay');
            if ~isempty(hTagged)
                delete(hTagged(isgraphics(hTagged)));
            end

            hFocal = findall(ax, 'Tag', 'nparaxial_v2_focal_length_overlay');
            if ~isempty(hFocal)
                delete(hFocal(isgraphics(hFocal)));
            end

            if ~isempty(app.UIFigure) && isvalid(app.UIFigure)
                hAnnotations = findall(app.UIFigure, ...
                    'Tag', 'nparaxial_v2_ray_diagram_annotation');
                if ~isempty(hAnnotations)
                    delete(hAnnotations(isgraphics(hAnnotations)));
                end
            end

            cla(ax);
            hold(ax, 'off');
            grid(ax, 'on');
            box(ax, 'on');
            xlabel(ax, 'z');
            ylabel(ax, 'y');
        end

        function refreshRayDiagramDisplay(app)
            if isempty(app.Data) || isempty(fieldnames(app.Data))
                app.setStatus("Overlay setting changed. Run Trace to draw ray diagram.", false);
                return
            end
            focalStatus = "";
            if string(app.TabGroup.SelectedTab.Title) == "Ray Diagram"
                focalStatus = app.plotRayDiagram();
            end
            if app.SystemFocalLengthCheckBox.Value
                switch focalStatus
                    case "visible"
                        app.setStatus("System focal length overlay refreshed.", false);
                    case "outside"
                        app.setStatus( ...
                            "System focal length computed; H'/F' outside current view.", ...
                            false);
                    case "afocal"
                        app.setStatus("No finite system focal length for this view.", false);
                    otherwise
                        app.setStatus("System focal length overlay refreshed.", false);
                end
                return
            end
            app.setStatus("Ray diagram overlay display refreshed.", false);
        end

        function selectTabByTitle(app, titleText)
            tabs = app.TabGroup.Children;
            titles = string({tabs.Title});
            idx = find(titles == string(titleText), 1);
            if ~isempty(idx)
                app.TabGroup.SelectedTab = tabs(idx);
                app.refreshSelectedTab();
            end
        end

        function focalStatus = plotRayDiagram(app)
            focalStatus = "";
            ax = app.RayAxes;
            app.clearRayDiagramAxesV2();
            hold(ax, 'on');
            grid(ax, 'on');
            box(ax, 'on');

            data = app.Data;
            yVals = [];
            zVals = [data.raySettings.z_obj; data.enabledElements.z; ...
                data.trace_z_final];
            legendHandles = gobjects(0, 1);
            legendNames = strings(0, 1);

            for q = 1:numel(data.bundleSet)
                bundle = data.bundleSet(q).bundle;
                styles = app.rayStylesForBundle(data.bundleSet(q));
                for r = 1:numel(bundle)
                    res = bundle(r).res;
                    for s = 1:numel(res.seg_z)
                        zSeg = res.seg_z{s};
                        ySeg = res.seg_y{s};
                        if numel(zSeg) < 2 || numel(ySeg) < 2
                            continue
                        end
                        hRay = plot(ax, zSeg, ySeg, ...
                            'Color', styles.color(r, :), ...
                            'LineStyle', char(styles.line_style(r)), ...
                            'LineWidth', styles.line_width(r), ...
                            'DisplayName', char(styles.display_name(r)));
                        legendHandles(end+1, 1) = hRay; %#ok<AGROW>
                        legendNames(end+1, 1) = styles.display_name(r); %#ok<AGROW>
                        yVals = [yVals; ySeg(:)]; %#ok<AGROW>
                        zVals = [zVals; zSeg(:)]; %#ok<AGROW>
                    end
                    if ~bundle(r).trc && isfinite(res.blocked_at_z)
                        hClip = plot(ax, res.blocked_at_z, res.blocked_y, ...
                            char(styles.marker(r)), ...
                            'Color', styles.color(r, :), ...
                            'LineWidth', 1.5, ...
                            'MarkerSize', 7, ...
                            'DisplayName', 'Clipped ray');
                        legendHandles(end+1, 1) = hClip; %#ok<AGROW>
                        legendNames(end+1, 1) = "Clipped ray"; %#ok<AGROW>
                        yVals = [yVals; res.blocked_y]; %#ok<AGROW>
                        zVals = [zVals; res.blocked_at_z]; %#ok<AGROW>
                    end
                end
            end

            finiteApertures = data.enabledElements.aperture_radius( ...
                isfinite(data.enabledElements.aperture_radius));
            yVals = [yVals; finiteApertures; -finiteApertures]; %#ok<AGROW>
            yLim = paddedLimitsLocal(yVals, 0.12);
            ylim(ax, yLim);

            for k = 1:height(data.enabledElements)
                app.drawElement(ax, data.enabledElements(k, :), yLim);
            end

            plot(ax, [data.raySettings.z_obj, data.raySettings.z_obj], yLim, ...
                ':', 'Color', [0.25 0.25 0.25], 'LineWidth', 1.0, ...
                'HandleVisibility', 'off');
            text(ax, data.raySettings.z_obj, yLim(2), ' object', ...
                'VerticalAlignment', 'top', ...
                'Color', [0.25 0.25 0.25], ...
                'HandleVisibility', 'off');

            if data.image.is_finite && data.image.is_real
                plot(ax, [data.image.z_img, data.image.z_img], yLim, ...
                    ':', 'Color', [0.25 0.25 0.25], 'LineWidth', 1.2, ...
                    'HandleVisibility', 'off');
                text(ax, data.image.z_img, yLim(2), ' image', ...
                    'VerticalAlignment', 'top', ...
                    'Color', [0.25 0.25 0.25], ...
                    'HandleVisibility', 'off');
                zVals = [zVals; data.image.z_img]; %#ok<AGROW>
            elseif data.image.is_finite && data.image.is_virtual
                zVals = [zVals; data.image.z_img]; %#ok<AGROW>
            end

            if app.SystemFocalLengthCheckBox.Value && ...
                    app.FitFocalLengthCheckBox.Value && ...
                    isfield(data, 'cardinal') && ~isempty(data.cardinal) && ...
                    isfield(data.cardinal, 'is_finite_power') && ...
                    logical(data.cardinal.is_finite_power)
                zVals = [zVals; data.cardinal.z_H2; data.cardinal.z_Fp]; %#ok<AGROW>
            end

            xLimits = paddedLimitsLocal(zVals, 0.04);
            xlim(ax, xLimits);
            if data.image.is_finite && data.image.is_virtual && ...
                    data.image.z_img >= xLimits(1) && data.image.z_img <= xLimits(2)
                plot(ax, [data.image.z_img, data.image.z_img], yLim, ...
                    '--', 'Color', [0.45 0.25 0.65], 'LineWidth', 1.2, ...
                    'HandleVisibility', 'off');
                text(ax, data.image.z_img, yLim(2), ' Virtual image', ...
                    'VerticalAlignment', 'top', ...
                    'Color', [0.45 0.25 0.65], ...
                    'HandleVisibility', 'off');
            end

            app.drawElementLabels(ax, data.enabledElements, yLim, xLimits);

            if isfield(data, 'object_type') && ...
                    string(data.object_type) == "Grating object"
                app.drawGratingOrderLabels(ax, data, yLim, xLimits);
            end
            if app.CardinalPointsCheckBox.Value && ~isempty(data.cardinal)
                nparaxial_plot_cardinal_points_yu(ax, data.cardinal, yLim, xLimits);
            end
            if app.StopPupilMarkersCheckBox.Value
                app.drawStopPupilMarkers(ax, yLim, xLimits);
            end
            if app.SystemFocalLengthCheckBox.Value
                focalStatus = app.plotSystemFocalLengthV2( ...
                    ax, data.cardinal, yLim, xLimits);
            end

            xlabel(ax, 'z');
            ylabel(ax, 'y');
            if isfield(data, 'object_type') && ...
                    string(data.object_type) == "Grating object"
                titleText = "V2 lightweight paraxial ray trace - grating object";
            else
                titleText = "V2 lightweight paraxial ray trace - " + ...
                    string(data.raySettings.fan_mode);
            end
            title(ax, titleText);
            if app.LegendCheckBox.Value
                [legendHandles, legendNames] = nparaxial_legend_unique_yu( ...
                    legendHandles, legendNames);
                if isempty(legendHandles)
                    legend(ax, 'off');
                else
                    lgd = legend(ax, legendHandles, cellstr(legendNames), ...
                        'Location', 'best');
                    lgd.Interpreter = 'none';
                end
            else
                legend(ax, 'off');
            end
            hold(ax, 'off');
        end

        function drawElement(app, ax, element, yLim)
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

            drewSurfaceCurve = false;
            if typeName == "surface" && app.SurfaceCurvesCheckBox.Value
                [zCurve, yCurve, curveInfo] = nparaxial_surface_curve_points_yu( ...
                    z, element.radius_R(1), a, max(abs(yLim)), 121, 1e-12);
                if curveInfo.is_finite_surface
                    plot(ax, zCurve, yCurve, ...
                        'Color', color, ...
                        'LineStyle', '-', ...
                        'LineWidth', 1.8, ...
                        'HandleVisibility', 'off');
                    drewSurfaceCurve = true;
                end
            end

            if isfinite(a) && ~drewSurfaceCurve
                plot(ax, [z, z], [-a, a], ...
                    'Color', color, ...
                    'LineStyle', lineStyle, ...
                    'LineWidth', 2.0, ...
                    'HandleVisibility', 'off');
                plot(ax, z, a, 'v', 'Color', color, ...
                    'MarkerSize', 5, 'HandleVisibility', 'off');
                plot(ax, z, -a, '^', 'Color', color, ...
                    'MarkerSize', 5, 'HandleVisibility', 'off');
            elseif ~drewSurfaceCurve
                plot(ax, [z, z], yLim, ...
                    'Color', color, ...
                    'LineStyle', lineStyle, ...
                    'LineWidth', 1.1, ...
                    'HandleVisibility', 'off');
            end

            if isfinite(a) && drewSurfaceCurve
                plot(ax, z, a, 'v', 'Color', color, ...
                    'MarkerSize', 5, 'HandleVisibility', 'off');
                plot(ax, z, -a, '^', 'Color', color, ...
                    'MarkerSize', 5, 'HandleVisibility', 'off');
            end

        end

        function drawElementLabels(app, ax, elements, yLim, xLimits)
            tag = 'nparaxial_v2_element_label';
            hOld = findall(ax, 'Tag', tag);
            if ~isempty(hOld)
                delete(hOld(isgraphics(hOld)));
            end
            if isempty(elements) || ~istable(elements) || ...
                    ~app.ShowElementLabelsCheckBox.Value
                return
            end

            labelStyle = string(app.ElementLabelStyleDropdown.Value);
            if labelStyle == "Off"
                return
            end

            ySpan = diff(yLim);
            if ySpan <= 0 || ~isfinite(ySpan)
                ySpan = 1;
            end
            zSpan = diff(xLimits);
            if zSpan <= 0 || ~isfinite(zSpan)
                zSpan = 1;
            end
            closeTol = max(1e-9, 0.018*zSpan);
            baseY = yLim(1) + 0.025*ySpan;
            yStep = 0.055*ySpan;
            xStep = 0.012*zSpan;

            [zSorted, idx] = sort(double(elements.z));
            groupNumbers = zeros(height(elements), 1);
            groupStart = 1;
            while groupStart <= numel(idx)
                groupEnd = groupStart;
                while groupEnd < numel(idx) && ...
                        abs(zSorted(groupEnd + 1) - zSorted(groupStart)) <= closeTol
                    groupEnd = groupEnd + 1;
                end
                groupIdx = idx(groupStart:groupEnd);
                offsets = 0:(numel(groupIdx) - 1);
                offsets = offsets - floor(numel(groupIdx)/2);
                groupNumbers(groupIdx) = offsets(:);
                groupStart = groupEnd + 1;
            end

            colorSet = lines(4);
            for k = 1:height(elements)
                z = double(elements.z(k));
                if ~isfinite(z)
                    continue
                end
                typeName = string(elements.type(k));
                color = app.elementColor(typeName, colorSet);
                offset = groupNumbers(k);
                xLabel = min(max(z + offset*xStep, xLimits(1)), xLimits(2));
                yLabel = min(max(baseY + abs(offset)*yStep, ...
                    yLim(1) + 0.02*ySpan), yLim(2) - 0.04*ySpan);
                text(ax, xLabel, yLabel, ...
                    app.formatElementLabel(elements(k, :), labelStyle), ...
                    'VerticalAlignment', 'bottom', ...
                    'HorizontalAlignment', 'center', ...
                    'Color', color, ...
                    'FontSize', 8, ...
                    'Interpreter', 'none', ...
                    'Clipping', 'on', ...
                    'Tag', tag, ...
                    'HandleVisibility', 'off');
            end
        end

        function label = formatElementLabel(~, element, labelStyle)
            elementId = string(element.element_id(1));
            if string(labelStyle) == "Detailed"
                label = elementId + " " + elementTypeLabelLocal( ...
                    string(element.type(1)));
            else
                label = elementId;
            end
        end

        function color = elementColor(~, typeName, colorSet)
            switch string(typeName)
                case "thinlens"
                    color = colorSet(1, :);
                case "surface"
                    color = colorSet(2, :);
                case "stop"
                    color = colorSet(3, :);
                otherwise
                    color = colorSet(4, :);
            end
        end

        function drawStopPupilMarkers(app, ax, yLim, xLimits)
            stopPupil = app.Data.stopPupil;
            if isempty(stopPupil) || ~isfield(stopPupil, 'stop') || ...
                    isempty(stopPupil.stop) || ~stopPupil.stop.has_stop
                return
            end
            app.drawDiagnosticPlane(ax, stopPupil.stop.selected_z, yLim, ...
                xLimits, " stop", [0.15 0.45 0.15], '--');
            if isfield(stopPupil, 'pupil') && ~isempty(stopPupil.pupil)
                app.drawDiagnosticPlane(ax, stopPupil.pupil.z_EP, yLim, ...
                    xLimits, " EP", [0.2 0.35 0.65], ':');
                app.drawDiagnosticPlane(ax, stopPupil.pupil.z_XP, yLim, ...
                    xLimits, " XP", [0.2 0.35 0.65], ':');
            end
        end

        function drawDiagnosticPlane(~, ax, z, yLim, xLimits, label, color, style)
            if isfinite(z) && z >= xLimits(1) && z <= xLimits(2)
                plot(ax, [z, z], yLim, style, ...
                    'Color', color, ...
                    'LineWidth', 1.0, ...
                    'HandleVisibility', 'off');
                text(ax, z, yLim(2), label, ...
                    'VerticalAlignment', 'top', ...
                    'Color', color, ...
                    'HandleVisibility', 'off');
            end
        end

        function drawGratingOrderLabels(app, ax, data, yLim, xLimits)
            if ~isfield(data, 'bundleSet') || isempty(data.bundleSet)
                return
            end
            ySpan = diff(yLim);
            if ySpan <= 0 || ~isfinite(ySpan)
                ySpan = 1;
            end
            xSpan = diff(xLimits);
            if xSpan <= 0 || ~isfinite(xSpan)
                xSpan = 1;
            end
            for q = 1:numel(data.bundleSet)
                if ~isfield(data.bundleSet(q), 'rays') || ...
                        ~istable(data.bundleSet(q).rays)
                    continue
                end
                rays = data.bundleSet(q).rays;
                if ~ismember("diffraction_order", ...
                        string(rays.Properties.VariableNames))
                    continue
                end
                nRays = height(rays);
                for r = 1:nRays
                    z0 = rays.z0(r);
                    y0 = rays.y0(r);
                    u0 = rays.u0(r);
                    xLabel = z0 + 0.035*xSpan;
                    xLabel = min(max(xLabel, xLimits(1)), xLimits(2));
                    yLabel = y0 + u0*(xLabel - z0);
                    yLabel = yLabel + (r - (nRays + 1)/2)*0.025*ySpan;
                    if ~isfinite(xLabel) || ~isfinite(yLabel)
                        continue
                    end
                    yLabel = min(max(yLabel, yLim(1) + 0.04*ySpan), ...
                        yLim(2) - 0.04*ySpan);
                    text(ax, xLabel, yLabel, ...
                        app.formatDiffractionOrderLabel( ...
                        rays.diffraction_order(r)), ...
                        'FontSize', 8, ...
                        'FontWeight', 'bold', ...
                        'Color', [0.18 0.18 0.18], ...
                        'HorizontalAlignment', 'left', ...
                        'VerticalAlignment', 'middle', ...
                        'Tag', 'nparaxial_v2_grating_order_label', ...
                        'HandleVisibility', 'off');
                end
            end
        end

        function status = plotSystemFocalLengthV2(~, ax, card, yLim, xLimits)
            status = "unavailable";
            tag = 'nparaxial_v2_focal_length_overlay';
            hOld = findall(ax, 'Tag', tag);
            if ~isempty(hOld)
                delete(hOld(isgraphics(hOld)));
            end

            labelColor = [0.18 0.18 0.18];
            markerColor = [0.42 0.22 0.55];
            textOpts = { ...
                'Units', 'normalized', ...
                'HorizontalAlignment', 'left', ...
                'VerticalAlignment', 'top', ...
                'FontWeight', 'bold', ...
                'FontSize', 10, ...
                'Color', labelColor, ...
                'BackgroundColor', [1 1 1], ...
                'EdgeColor', [0.75 0.75 0.75], ...
                'Margin', 4, ...
                'Tag', tag, ...
                'HandleVisibility', 'off'};

            if nargin < 3 || isempty(card) || ~isstruct(card) || ...
                    ~isfield(card, 'is_finite_power') || ...
                    ~logical(card.is_finite_power)
                text(ax, 0.02, 0.97, 'No finite EFL: C approx 0', ...
                    textOpts{:});
                status = "afocal";
                return
            end

            zHp = double(card.z_H2);
            zFp = double(card.z_Fp);
            fEff = zFp - zHp;
            if ~isfinite(fEff) || ~isfinite(zHp) || ~isfinite(zFp)
                text(ax, 0.02, 0.97, 'No finite EFL: C approx 0', ...
                    textOpts{:});
                status = "afocal";
                return
            end

            inside = zHp >= xLimits(1) && zHp <= xLimits(2) && ...
                zFp >= xLimits(1) && zFp <= xLimits(2);
            if inside
                label = sprintf('EFL f'' = %.6g mm', fEff);
            else
                label = sprintf( ...
                    'EFL f'' = %.6g mm\nH'' / F'' outside current view', ...
                    fEff);
            end
            text(ax, 0.02, 0.97, label, textOpts{:});

            if ~inside
                status = "outside";
                return
            end

            ySpan = diff(yLim);
            if ySpan <= 0 || ~isfinite(ySpan)
                ySpan = 1;
            end
            yBracket = yLim(1) + 0.78*ySpan;
            tickHalf = 0.045*ySpan;
            labelY = min(yLim(2) - 0.04*ySpan, yBracket + 0.07*ySpan);

            plot(ax, [zHp, zHp], yLim, '-.', ...
                'Color', markerColor, ...
                'LineWidth', 1.0, ...
                'Tag', tag, ...
                'HandleVisibility', 'off');
            plot(ax, [zFp, zFp], yLim, ':', ...
                'Color', markerColor, ...
                'LineWidth', 1.1, ...
                'Tag', tag, ...
                'HandleVisibility', 'off');
            plot(ax, [zHp, zFp], [yBracket, yBracket], '-', ...
                'Color', markerColor, ...
                'LineWidth', 1.4, ...
                'Tag', tag, ...
                'HandleVisibility', 'off');
            plot(ax, [zHp, zHp], yBracket + tickHalf*[-1, 1], '-', ...
                'Color', markerColor, ...
                'LineWidth', 1.4, ...
                'Tag', tag, ...
                'HandleVisibility', 'off');
            plot(ax, [zFp, zFp], yBracket + tickHalf*[-1, 1], '-', ...
                'Color', markerColor, ...
                'LineWidth', 1.4, ...
                'Tag', tag, ...
                'HandleVisibility', 'off');

            text(ax, zHp, yLim(2) - 0.08*ySpan, 'H''', ...
                'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'top', ...
                'FontWeight', 'bold', ...
                'Color', markerColor, ...
                'Tag', tag, ...
                'HandleVisibility', 'off');
            text(ax, zFp, yLim(2) - 0.08*ySpan, 'F''', ...
                'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'top', ...
                'FontWeight', 'bold', ...
                'Color', markerColor, ...
                'Tag', tag, ...
                'HandleVisibility', 'off');
            text(ax, mean([zHp, zFp]), labelY, ...
                sprintf('f'' = %.6g mm', fEff), ...
                'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'bottom', ...
                'FontWeight', 'bold', ...
                'Color', markerColor, ...
                'Tag', tag, ...
                'HandleVisibility', 'off');
            status = "visible";
        end

        function styles = rayStylesForBundle(app, bundleSetItem)
            bundle = bundleSetItem.bundle;
            clipped = ~[bundle.trc].';
            if isfield(bundleSetItem, 'rays') && istable(bundleSetItem.rays)
                rayColumns = string(bundleSetItem.rays.Properties.VariableNames);
                if ismember("diffraction_order", rayColumns)
                    propagatingOrders = [];
                    if isfield(app.Data, 'gratingInfo') && ...
                            isstruct(app.Data.gratingInfo) && ...
                            isfield(app.Data.gratingInfo, 'propagating_orders')
                        propagatingOrders = ...
                            app.Data.gratingInfo.propagating_orders;
                    end
                    styles = nparaxial_grating_order_style_yu( ...
                        bundleSetItem.rays, clipped, propagatingOrders);
                    return
                end
                styles = nparaxial_ray_role_style_yu(bundleSetItem.rays, clipped);
                return
            end
            names = strings(numel(bundle), 1);
            for k = 1:numel(bundle)
                names(k) = string(bundle(k).name);
            end
            rayTable = table(names, 'VariableNames', {'name'});
            styles = nparaxial_ray_role_style_yu(rayTable, clipped);
        end

        function label = formatDiffractionOrderLabel(~, orderValue)
            orderValue = round(double(orderValue));
            if orderValue > 0
                label = "m = +" + string(orderValue);
            else
                label = "m = " + string(orderValue);
            end
        end

        function updateSystemMatrix(app)
            data = app.Data;
            img = data.image;
            matrixLines = [
                "System matrix"
                "-------------"
                nparaxial_matrix_to_text_yu(img.M_ref, 'Object to reference M')
                ""
                nparaxial_matrix_to_text_yu( ...
                data.matrixChain.final_matrix, 'Object to trace endpoint M')
                sprintf('det(M_ref) = %.12g', det(img.M_ref))
                sprintf('Image classification = %s', string(img.type))
                sprintf('Transverse magnification m = %.6g', img.m)
                ];
            if isfield(data, 'object_type') && ...
                    string(data.object_type) == "Grating object"
                matrixLines = [
                    matrixLines
                    ""
                    "Grating object is a source/ray-launch condition; it is not included in the ABCD system matrix."
                    ];
            end
            app.MatrixTextArea.Value = cellstr(matrixLines);
            app.MatrixChainTextArea.Value = cellstr( ...
                nparaxial_matrix_chain_text_yu(data.matrixChain));
            app.MatrixChainTable.Data = data.matrixChain.steps;
            app.ElementTable.Data = data.enabledElements;
        end

        function updateCardinal(app)
            data = app.Data;
            img = data.image;
            if isempty(data.cardinal)
                app.CardinalTextArea.Value = {'Cardinal data unavailable.'};
                app.CardinalTable.Data = table();
                return
            end
            card = data.cardinal;
            focalLines = {'System focal length: no finite EFL (C approx 0)'};
            if isfield(card, 'is_finite_power') && logical(card.is_finite_power)
                zHp = card.z_H2;
                zFp = card.z_Fp;
                fEff = zFp - zHp;
                viewText = 'not available';
                if ~isempty(app.RayAxes) && isvalid(app.RayAxes)
                    xLimits = xlim(app.RayAxes);
                    if all(isfinite([zHp, zFp, xLimits]))
                        if zHp >= xLimits(1) && zHp <= xLimits(2) && ...
                                zFp >= xLimits(1) && zFp <= xLimits(2)
                            viewText = 'yes';
                        else
                            viewText = 'no';
                        end
                    end
                end
                focalLines = {
                    sprintf('f''_eff = %.6g mm', fEff)
                    sprintf('z_H'' = %.6g, z_F'' = %.6g', zHp, zFp)
                    sprintf('H''/F'' inside current Ray Diagram view: %s', ...
                    viewText)
                    };
            end
            cardinalLines = {
                'Cardinal / Gaussian diagnostics'
                '-------------------------------'
                sprintf('Reference planes: z1 = %.6g, z2 = %.6g', card.z1, card.z2)
                sprintf('Classification: %s', card.classification)
                sprintf('Image classification: %s', string(img.type))
                sprintf('Phi = %.6g', card.Phi)
                sprintf('f'' = %.6g, f = %.6g', card.f_prime, card.f)
                sprintf('F = %.6g, H = %.6g, N = %.6g', ...
                card.z_F, card.z_H1, card.z_N1)
                sprintf('N'' = %.6g, H'' = %.6g, F'' = %.6g', ...
                card.z_N2, card.z_H2, card.z_Fp)
                };
            cardinalLines = [cardinalLines; focalLines(:); ...
                {sprintf('Transverse magnification m = %.6g', img.m)}];
            if isfield(data, 'object_type') && ...
                    string(data.object_type) == "Grating object"
                cardinalLines = [cardinalLines; { ...
                    'Cardinal data are for the optical system only; grating changes launch angles/order rays.'}];
            end
            app.CardinalTextArea.Value = cardinalLines;
            app.CardinalTable.Data = card.table;
        end

        function updateStopPupils(app)
            stopPupil = app.Data.stopPupil;
            clip = app.clippingSummaryTable();
            if isempty(stopPupil) || ~isfield(stopPupil, 'stop') || ...
                    isempty(stopPupil.stop) || ~stopPupil.stop.has_stop
                app.StopPupilTextArea.Value = {
                    'Stop / pupil diagnostics'
                    '------------------------'
                    'No finite aperture stop selected for this prescription.'
                    sprintf('Traced rays: %d, clipped rays: %d', ...
                    sum(clip.traced), sum(~clip.traced))
                    };
                app.StopPupilTable.Data = clipToQuantityTableLocal(clip);
                return
            end

            stop = stopPupil.stop;
            lines = {
                'Stop / pupil diagnostics'
                '------------------------'
                sprintf('Aperture stop: %s', stop.selected_element_id)
                sprintf('Stop z = %.6g, radius = %.6g', ...
                stop.selected_z, stop.selected_aperture_radius)
                char(stop.note)
                sprintf('Traced rays: %d, clipped rays: %d', ...
                sum(clip.traced), sum(~clip.traced))
                };
            pupilTable = table();
            if isfield(stopPupil, 'pupil') && ~isempty(stopPupil.pupil)
                pupil = stopPupil.pupil;
                lines = [lines; {
                    sprintf('Entrance pupil z = %.6g, radius = %.6g', ...
                    pupil.z_EP, pupil.r_EP)
                    sprintf('Exit pupil z = %.6g, radius = %.6g', ...
                    pupil.z_XP, pupil.r_XP)
                    sprintf('Pupil magnifications: entrance %.6g, exit %.6g', ...
                    pupil.m_EP, pupil.m_XP)
                    }];
                pupilTable = pupil.table;
            else
                lines{end+1, 1} = ...
                    'Pupil conjugates are not available for this prescription.';
            end
            app.StopPupilTextArea.Value = lines;
            app.StopPupilTable.Data = [pupilTable; clipToQuantityTableLocal(clip)];
        end

        function T = clippingSummaryTable(app)
            ray_name = strings(0, 1);
            traced = false(0, 1);
            blocked_z = NaN(0, 1);
            blocked_y = NaN(0, 1);
            for q = 1:numel(app.Data.bundleSet)
                bundle = app.Data.bundleSet(q).bundle;
                for r = 1:numel(bundle)
                    ray_name(end+1, 1) = string(bundle(r).name); %#ok<AGROW>
                    traced(end+1, 1) = bundle(r).trc; %#ok<AGROW>
                    blocked_z(end+1, 1) = bundle(r).res.blocked_at_z; %#ok<AGROW>
                    blocked_y(end+1, 1) = bundle(r).res.blocked_y; %#ok<AGROW>
                end
            end
            T = table(ray_name, traced, blocked_z, blocked_y);
        end

        function T = matrixOverviewTable(~, data)
            quantity = [
                "z_object"; "z_reference"; "trace_z_final"; "z_image"; ...
                "image_is_finite"; "image_is_real"; "image_is_virtual"; ...
                "A_ref"; "B_ref"; "C_ref"; "D_ref"; "m"
                ];
            value = [
                data.raySettings.z_obj; data.image.z_ref; ...
                data.trace_z_final; data.image.z_img; ...
                double(data.image.is_finite); double(data.image.is_real); ...
                double(data.image.is_virtual); data.image.A_ref; ...
                data.image.B_ref; data.image.C_ref; data.image.D_ref; ...
                data.image.m
                ];
            T = table(quantity, value);
        end

        function clearDisplays(app, message)
            if ~isempty(app.RayAxes) && isvalid(app.RayAxes)
                app.clearRayDiagramAxesV2();
                title(app.RayAxes, message);
                xlabel(app.RayAxes, 'z');
                ylabel(app.RayAxes, 'y');
            end
            app.MatrixTextArea.Value = {message};
            app.MatrixChainTextArea.Value = {message};
            app.MatrixChainTable.Data = table();
            app.ElementTable.Data = table();
            app.CardinalTextArea.Value = {message};
            app.CardinalTable.Data = table();
            app.StopPupilTextArea.Value = {message};
            app.StopPupilTable.Data = table();
            app.TimingLabel.Text = 'Run time: --';
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
                app.requestTrace();
            catch ME
                app.setStatus("Add row error: " + string(ME.message), true);
            end
        end

        function duplicatePrescriptionRow(app)
            try
                T = nparaxial_validate_prescription_yu(app.PrescriptionTable.Data);
                if isempty(app.SelectedPrescriptionRows)
                    idx = height(T);
                else
                    idx = app.SelectedPrescriptionRows(end);
                end
                newRow = T(idx, :);
                newRow.element_id = app.uniqueElementId( ...
                    T, app.prefixForType(newRow.type));
                newRow.event_order = max(T.event_order) + 1;
                app.PrescriptionTable.Data = [T; newRow];
                app.SelectedPrescriptionRows = height(T) + 1;
                app.requestTrace();
            catch ME
                app.setStatus("Duplicate row error: " + string(ME.message), true);
            end
        end

        function deleteSelectedPrescriptionRows(app)
            try
                T = nparaxial_validate_prescription_yu(app.PrescriptionTable.Data);
                if isempty(app.SelectedPrescriptionRows)
                    app.setStatus("Select prescription row(s) to delete.", true);
                    return
                end
                keep = true(height(T), 1);
                keep(app.SelectedPrescriptionRows) = false;
                if ~any(keep)
                    app.setStatus("At least one prescription row is required.", true);
                    return
                end
                app.PrescriptionTable.Data = T(keep, :);
                app.SelectedPrescriptionRows = [];
                app.requestTrace();
            catch ME
                app.setStatus("Delete row error: " + string(ME.message), true);
            end
        end

        function sortPrescriptionTable(app)
            try
                T = nparaxial_validate_prescription_yu(app.PrescriptionTable.Data);
                [~, idx] = sortrows([T.z, T.event_order]);
                app.PrescriptionTable.Data = T(idx, :);
                app.SelectedPrescriptionRows = [];
                app.requestTrace();
            catch ME
                app.setStatus("Sort prescription error: " + string(ME.message), true);
            end
        end

        function newRow = defaultPrescriptionRow(app, T, elementType)
            elementType = lower(strtrim(string(elementType)));
            if isempty(T)
                zDefault = 0;
                eventOrder = 1;
                nBefore = 1;
            else
                zDefault = max(T.z) + 25;
                eventOrder = max(T.event_order) + 1;
                nBefore = T.n_after(end);
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

        function lines = equationLines(~)
            lines = {
                'V2 lightweight system viewer equations'
                '======================================'
                ''
                'Ray vector convention:'
                '    r = [y; u]'
                '    y is meridional height and u is paraxial angle in radians.'
                ''
                'Translation:'
                '    T(d) = [1 d; 0 1]'
                '    y2 = y1 + d*u1,   u2 = u1'
                ''
                'Thin lens:'
                '    L(f) = [1 0; -1/f 1]'
                ''
                'Spherical refracting surface:'
                '    S = [1 0; (n1-n2)/(n2 R) n1/n2]'
                '    R > 0 center to the right; R < 0 center to the left.'
                ''
                'Stop and dummy planes:'
                '    Identity matrix event; finite apertures clip rays at the event plane.'
                ''
                'Image classification:'
                '    For M = [A B; C D] at the final reference plane,'
                '    translate by x and solve B + x*D = 0.'
                '    x >= 0 gives finite real image; x < 0 gives finite virtual image.'
                '    D approximately zero gives image at infinity / no finite image.'
                ''
                'Cardinal/Gaussian definitions:'
                '    F and F'' are front and rear focal points.'
                '    H and H'' are first and second principal points.'
                '    N and N'' are first and second nodal points.'
                '    These come from the first-order ABCD matrix.'
                ''
                'Grating object / diffraction-order launch:'
                '    n_out sin(theta_m) = n_in sin(theta_i) + m lambda / period'
                ''
                'Paraxial launch coordinate:'
                '    u0 = theta_m  [radians]'
                ''
                'Normal incidence, same medium:'
                '    sin(theta_m) = m lambda / period'
                '    u_m approx m lambda / (n period)'
                ''
                'Grating note:'
                '    The grating object is not an ABCD matrix element.'
                '    It generates initial ray angles for each diffraction order.'
                ''
                'Heavy diagnostics:'
                '    Paraxial validity diagnostics, field sweeps, reports, profiling,'
                '    and batch studies are available through script workflows, not V2 UI.'
                };
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

        function prescription = savePrescriptionCsv(app, filename)
            prescription = app.validatedPrescriptionFromTable();
            save_prescription_csv_yu(prescription, filename);
            app.setStatus("Saved prescription CSV: " + string(filename), false);
        end

        function prescription = loadPrescriptionCsv(app, filename)
            prescription = nparaxial_validate_prescription_yu( ...
                load_prescription_csv_yu(filename));
            app.applyLoadedPrescription(prescription, ...
                'Prescription CSV loaded. Run Trace to refresh V2.');
            app.setStatus("Loaded prescription CSV: " + string(filename), false);
        end

        function prescription = savePrescriptionMat(app, filename)
            prescription = app.validatedPrescriptionFromTable();
            save_prescription_mat_yu(prescription, filename);
            app.setStatus("Saved prescription MAT: " + string(filename), false);
        end

        function prescription = loadPrescriptionMat(app, filename)
            prescription = nparaxial_validate_prescription_yu( ...
                load_prescription_mat_yu(filename));
            app.applyLoadedPrescription(prescription, ...
                'Prescription MAT loaded. Run Trace to refresh V2.');
            app.setStatus("Loaded prescription MAT: " + string(filename), false);
        end

        function app = YU_NParaxialSurface_App_V2
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


function limits = paddedLimitsLocal(values, fraction)
    values = double(values(:));
    values = values(isfinite(values));
    if isempty(values)
        values = [-1; 1];
    end
    lo = min(values);
    hi = max(values);
    if lo == hi
        lo = lo - 1;
        hi = hi + 1;
    end
    pad = fraction*(hi - lo);
    limits = [lo - pad, hi + pad];
end


function T = clipToQuantityTableLocal(clip)
    quantity = [
        "traced_ray_count"
        "clipped_ray_count"
        ];
    value = [
        sum(clip.traced)
        sum(~clip.traced)
        ];
    T = table(quantity, value);
end


function value = firstBundleSetValueLocal(bundleSet, fieldName, defaultValue)
    value = defaultValue;
    if ~isempty(bundleSet) && isfield(bundleSet, fieldName)
        value = bundleSet(1).(fieldName);
    end
end


function label = elementTypeLabelLocal(typeName)
    switch string(typeName)
        case "thinlens"
            label = "thin lens";
        case "surface"
            label = "surface";
        case "stop"
            label = "stop";
        case "dummy"
            label = "dummy";
        otherwise
            label = string(typeName);
    end
end
