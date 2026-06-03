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
        DiagnosticFieldField matlab.ui.control.NumericEditField
        ManualUMaxField matlab.ui.control.NumericEditField
        PresetDropdown matlab.ui.control.DropDown
        RayFanModeDropdown matlab.ui.control.DropDown
        SurfaceCurvesCheckBox matlab.ui.control.CheckBox
        FirstSegmentPenaltyCheckBox matlab.ui.control.CheckBox
        SurfaceAngleSchematicCheckBox matlab.ui.control.CheckBox
        ValiditySweepModeDropdown matlab.ui.control.DropDown
        ValiditySweepFieldMinField matlab.ui.control.NumericEditField
        ValiditySweepFieldMaxField matlab.ui.control.NumericEditField
        ValiditySweepCountField matlab.ui.control.NumericEditField
        ValiditySweepMetricDropdown matlab.ui.control.DropDown
        ValiditySweepStatusLabel matlab.ui.control.Label
        ValiditySweepAxes matlab.ui.control.UIAxes
        ValiditySweepTable matlab.ui.control.Table

        RayAxes matlab.ui.control.UIAxes
        SummaryTextArea matlab.ui.control.TextArea
        MatrixChainTextArea matlab.ui.control.TextArea
        FinalMatrixTextArea matlab.ui.control.TextArea
        EquationsTextArea matlab.ui.control.TextArea
        CardinalTextArea matlab.ui.control.TextArea
        PupilTextArea matlab.ui.control.TextArea
        VignettingTextArea matlab.ui.control.TextArea
        ValidityTextArea matlab.ui.control.TextArea
        ChiefTextArea matlab.ui.control.TextArea
        InvariantTextArea matlab.ui.control.TextArea
        MatrixTable matlab.ui.control.Table
        MatrixChainTable matlab.ui.control.Table
        CardinalTable matlab.ui.control.Table
        PupilCandidateTable matlab.ui.control.Table
        VignettingCandidateTable matlab.ui.control.Table
        VignettingCumulativeTable matlab.ui.control.Table
        ValiditySummaryTable matlab.ui.control.Table
        ValiditySegmentTable matlab.ui.control.Table
        ValidityEventTable matlab.ui.control.Table
        ChiefRayTable matlab.ui.control.Table
        ChiefEventTable matlab.ui.control.Table
        InvariantSummaryTable matlab.ui.control.Table
        PhaseSpaceTable matlab.ui.control.Table
        PrescriptionTable matlab.ui.control.Table

        Data struct
        IsRunning logical = false
        IsDirty logical = true
        IsValiditySweepDirty logical = true
        SelectedPrescriptionRows double = []
        LastRefreshedTabTitle string = ""
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
            app.createMenus();

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

            app.addControlLabel('Diagnostic field y', 7);
            app.DiagnosticFieldField = app.addNumericField(7, 0);

            note = uilabel(app.ControlGrid, ...
                'Text', ['Prescription type values: thinlens, surface, stop, dummy. ', ...
                'A finite aperture_radius clips rays at any enabled element. ', ...
                'Only surface elements may change n_before to n_after. ', ...
                'Ray fan mode selects manual fixed-angle or aperture-limited admitted-cone sampling.'], ...
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
                'Value', 'Two thin lenses', ...
                'ValueChangedFcn', @(~, ~) app.requestTrace());
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
            rayGrid = uigridlayout(rayTab, [2 1]);
            rayGrid.RowHeight = {335, '1x'};
            rayGrid.ColumnWidth = {'1x'};
            rayGrid.Padding = [8 8 8 8];
            rayGrid.RowSpacing = 8;

            rayTopGrid = uigridlayout(rayGrid, [1 2]);
            rayTopGrid.Layout.Row = 1;
            rayTopGrid.Layout.Column = 1;
            rayTopGrid.ColumnWidth = {330, '1x'};
            rayTopGrid.RowHeight = {'1x'};
            rayTopGrid.Padding = [0 0 0 0];
            rayTopGrid.ColumnSpacing = 8;

            controlsPanel = uipanel(rayTopGrid, ...
                'Title', 'Ray Fan / Prescription Controls', ...
                'FontWeight', 'bold');
            controlsPanel.Layout.Row = 1;
            controlsPanel.Layout.Column = 1;

            app.PrescriptionButtonGrid = uigridlayout(controlsPanel, [10 2]);
            app.PrescriptionButtonGrid.RowHeight = {24, 24, 22, 24, 24, 28, 28, 28, 28, 30};
            app.PrescriptionButtonGrid.ColumnWidth = {'1x', '1x'};
            app.PrescriptionButtonGrid.Padding = [8 8 8 8];
            app.PrescriptionButtonGrid.RowSpacing = 5;
            app.PrescriptionButtonGrid.ColumnSpacing = 6;

            rayFanLabel = uilabel(app.PrescriptionButtonGrid, ...
                'Text', 'Ray fan mode', ...
                'HorizontalAlignment', 'left');
            rayFanLabel.Layout.Row = 1;
            rayFanLabel.Layout.Column = 1;
            app.RayFanModeDropdown = uidropdown(app.PrescriptionButtonGrid, ...
                'Items', {'Manual fixed-angle fan', ...
                'Aperture-limited admitted cone'}, ...
                'Value', 'Manual fixed-angle fan', ...
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
                'ValueChangedFcn', @(~, ~) app.refreshRayDiagramDisplay());
            app.SurfaceCurvesCheckBox.Layout.Row = 4;
            app.SurfaceCurvesCheckBox.Layout.Column = 1;

            app.FirstSegmentPenaltyCheckBox = uicheckbox(app.PrescriptionButtonGrid, ...
                'Text', 'First-segment penalty', ...
                'Value', false, ...
                'ValueChangedFcn', @(~, ~) app.refreshRayDiagramDisplay());
            app.FirstSegmentPenaltyCheckBox.Layout.Row = 4;
            app.FirstSegmentPenaltyCheckBox.Layout.Column = 2;

            app.SurfaceAngleSchematicCheckBox = uicheckbox(app.PrescriptionButtonGrid, ...
                'Text', 'Surface-angle schematic', ...
                'Value', false, ...
                'ValueChangedFcn', @(~, ~) app.refreshRayDiagramDisplay());
            app.SurfaceAngleSchematicCheckBox.Layout.Row = 5;
            app.SurfaceAngleSchematicCheckBox.Layout.Column = [1 2];

            app.addPrescriptionButton('Add Thin Lens', 6, 1, ...
                @(~, ~) app.addPrescriptionRow("thinlens"));
            app.addPrescriptionButton('Add Surface', 6, 2, ...
                @(~, ~) app.addPrescriptionRow("surface"));
            app.addPrescriptionButton('Add Stop', 7, 1, ...
                @(~, ~) app.addPrescriptionRow("stop"));
            app.addPrescriptionButton('Add Dummy', 7, 2, ...
                @(~, ~) app.addPrescriptionRow("dummy"));
            app.addPrescriptionButton('Duplicate Row', 8, 1, ...
                @(~, ~) app.duplicatePrescriptionRow());
            app.addPrescriptionButton('Delete Selected Row', 8, 2, ...
                @(~, ~) app.deleteSelectedPrescriptionRows());
            app.addPrescriptionButton('Sort Prescription', 9, 1, ...
                @(~, ~) app.sortPrescriptionTable());
            app.addPrescriptionButton('Check Prescription', 9, 2, ...
                @(~, ~) app.checkPrescription());
            app.addPrescriptionButton('Run Trace', 10, [1 2], ...
                @(~, ~) app.runTrace());

            app.PrescriptionTable = uitable(rayTopGrid);
            app.PrescriptionTable.Layout.Row = 1;
            app.PrescriptionTable.Layout.Column = 2;
            app.PrescriptionTable.ColumnEditable = true(1, 10);
            app.PrescriptionTable.CellEditCallback = @(~, ~) app.requestTrace();
            app.PrescriptionTable.CellSelectionCallback = ...
                @(~, event) app.selectPrescriptionRows(event);

            app.RayAxes = uiaxes(rayGrid);
            app.RayAxes.Layout.Row = 2;
            app.RayAxes.Layout.Column = 1;

            summaryTab = uitab(app.TabGroup, 'Title', 'System Matrix / Image Summary');
            summaryGrid = uigridlayout(summaryTab, [4 1]);
            summaryGrid.RowHeight = {120, 135, 120, '1x'};
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

            matrixOverviewGrid = uigridlayout(summaryGrid, [1 2]);
            matrixOverviewGrid.Layout.Row = 2;
            matrixOverviewGrid.Layout.Column = 1;
            matrixOverviewGrid.ColumnWidth = {'1x', '1x'};
            matrixOverviewGrid.RowHeight = {'1x'};
            matrixOverviewGrid.Padding = [0 0 0 0];
            matrixOverviewGrid.ColumnSpacing = 8;

            app.MatrixTable = uitable(matrixOverviewGrid);
            app.MatrixTable.Layout.Row = 1;
            app.MatrixTable.Layout.Column = 1;

            app.FinalMatrixTextArea = uitextarea(matrixOverviewGrid, ...
                'Editable', 'off', ...
                'FontName', 'Consolas');
            app.FinalMatrixTextArea.Layout.Row = 1;
            app.FinalMatrixTextArea.Layout.Column = 2;

            app.MatrixChainTextArea = uitextarea(summaryGrid, ...
                'Editable', 'off', ...
                'FontName', 'Consolas');
            if isprop(app.MatrixChainTextArea, 'WordWrap')
                app.MatrixChainTextArea.WordWrap = 'off';
            end
            app.MatrixChainTextArea.Layout.Row = 3;
            app.MatrixChainTextArea.Layout.Column = 1;

            app.MatrixChainTable = uitable(summaryGrid);
            app.MatrixChainTable.Layout.Row = 4;
            app.MatrixChainTable.Layout.Column = 1;

            cardinalTab = uitab(app.TabGroup, 'Title', 'Cardinal / Gaussian');
            cardinalGrid = uigridlayout(cardinalTab, [2 1]);
            cardinalGrid.RowHeight = {150, '1x'};
            cardinalGrid.Padding = [8 8 8 8];
            cardinalGrid.RowSpacing = 8;
            app.CardinalTextArea = uitextarea(cardinalGrid, ...
                'Editable', 'off', ...
                'FontName', 'Consolas');
            app.CardinalTextArea.Layout.Row = 1;
            app.CardinalTextArea.Layout.Column = 1;
            app.CardinalTable = uitable(cardinalGrid);
            app.CardinalTable.Layout.Row = 2;
            app.CardinalTable.Layout.Column = 1;

            pupilTab = uitab(app.TabGroup, 'Title', 'Stops / Pupils');
            pupilGrid = uigridlayout(pupilTab, [2 1]);
            pupilGrid.RowHeight = {170, '1x'};
            pupilGrid.Padding = [8 8 8 8];
            pupilGrid.RowSpacing = 8;
            app.PupilTextArea = uitextarea(pupilGrid, ...
                'Editable', 'off', ...
                'FontName', 'Consolas');
            app.PupilTextArea.Layout.Row = 1;
            app.PupilTextArea.Layout.Column = 1;
            app.PupilCandidateTable = uitable(pupilGrid);
            app.PupilCandidateTable.Layout.Row = 2;
            app.PupilCandidateTable.Layout.Column = 1;

            vignettingTab = uitab(app.TabGroup, 'Title', 'Vignetting');
            vignettingGrid = uigridlayout(vignettingTab, [5 1]);
            vignettingGrid.RowHeight = {150, 22, '1x', 22, '1x'};
            vignettingGrid.Padding = [8 8 8 8];
            vignettingGrid.RowSpacing = 8;
            app.VignettingTextArea = uitextarea(vignettingGrid, ...
                'Editable', 'off', ...
                'FontName', 'Consolas');
            app.VignettingTextArea.Layout.Row = 1;
            app.VignettingTextArea.Layout.Column = 1;

            candidateLabel = uilabel(vignettingGrid, ...
                'Text', 'Candidate aperture intervals', ...
                'FontWeight', 'bold');
            candidateLabel.Layout.Row = 2;
            candidateLabel.Layout.Column = 1;
            app.VignettingCandidateTable = uitable(vignettingGrid);
            app.VignettingCandidateTable.Layout.Row = 3;
            app.VignettingCandidateTable.Layout.Column = 1;

            cumulativeLabel = uilabel(vignettingGrid, ...
                'Text', 'Cumulative interval intersection', ...
                'FontWeight', 'bold');
            cumulativeLabel.Layout.Row = 4;
            cumulativeLabel.Layout.Column = 1;
            app.VignettingCumulativeTable = uitable(vignettingGrid);
            app.VignettingCumulativeTable.Layout.Row = 5;
            app.VignettingCumulativeTable.Layout.Column = 1;

            validityTab = uitab(app.TabGroup, 'Title', 'Paraxial Validity');
            validityGrid = uigridlayout(validityTab, [3 1]);
            validityGrid.RowHeight = {110, 92, '1x'};
            validityGrid.Padding = [8 8 8 8];
            validityGrid.RowSpacing = 8;
            app.ValidityTextArea = uitextarea(validityGrid, ...
                'Editable', 'off', ...
                'FontName', 'Consolas');
            app.ValidityTextArea.Layout.Row = 1;
            app.ValidityTextArea.Layout.Column = 1;

            sweepControlsGrid = uigridlayout(validityGrid, [2 8]);
            sweepControlsGrid.Layout.Row = 2;
            sweepControlsGrid.Layout.Column = 1;
            sweepControlsGrid.RowHeight = {26, 30};
            sweepControlsGrid.ColumnWidth = {92, 120, 66, 72, 66, 72, 112, '1x'};
            sweepControlsGrid.Padding = [0 0 0 0];
            sweepControlsGrid.RowSpacing = 4;
            sweepControlsGrid.ColumnSpacing = 6;

            sweepModeLabel = uilabel(sweepControlsGrid, ...
                'Text', 'Sweep mode', ...
                'HorizontalAlignment', 'left');
            sweepModeLabel.Layout.Row = 1;
            sweepModeLabel.Layout.Column = 1;
            app.ValiditySweepModeDropdown = uidropdown(sweepControlsGrid, ...
                'Items', {'Current field only', 'Symmetric field sweep', ...
                'Custom min/max field sweep'}, ...
                'Value', 'Symmetric field sweep', ...
                'ValueChangedFcn', @(~, ~) app.noteValiditySweepControlsChanged());
            app.ValiditySweepModeDropdown.Layout.Row = 1;
            app.ValiditySweepModeDropdown.Layout.Column = 2;

            fieldMinLabel = uilabel(sweepControlsGrid, ...
                'Text', 'Field min', ...
                'HorizontalAlignment', 'left');
            fieldMinLabel.Layout.Row = 1;
            fieldMinLabel.Layout.Column = 3;
            app.ValiditySweepFieldMinField = uieditfield(sweepControlsGrid, ...
                'numeric', ...
                'Value', -10, ...
                'ValueChangedFcn', @(~, ~) app.noteValiditySweepControlsChanged());
            app.ValiditySweepFieldMinField.Layout.Row = 1;
            app.ValiditySweepFieldMinField.Layout.Column = 4;

            fieldMaxLabel = uilabel(sweepControlsGrid, ...
                'Text', 'Field max', ...
                'HorizontalAlignment', 'left');
            fieldMaxLabel.Layout.Row = 1;
            fieldMaxLabel.Layout.Column = 5;
            app.ValiditySweepFieldMaxField = uieditfield(sweepControlsGrid, ...
                'numeric', ...
                'Value', 10, ...
                'ValueChangedFcn', @(~, ~) app.noteValiditySweepControlsChanged());
            app.ValiditySweepFieldMaxField.Layout.Row = 1;
            app.ValiditySweepFieldMaxField.Layout.Column = 6;

            fieldCountLabel = uilabel(sweepControlsGrid, ...
                'Text', 'Field points', ...
                'HorizontalAlignment', 'left');
            fieldCountLabel.Layout.Row = 1;
            fieldCountLabel.Layout.Column = 7;
            app.ValiditySweepCountField = uieditfield(sweepControlsGrid, ...
                'numeric', ...
                'Limits', [1 Inf], ...
                'RoundFractionalValues', 'on', ...
                'Value', 11, ...
                'ValueChangedFcn', @(~, ~) app.noteValiditySweepControlsChanged());
            app.ValiditySweepCountField.Layout.Row = 1;
            app.ValiditySweepCountField.Layout.Column = 8;

            metricLabel = uilabel(sweepControlsGrid, ...
                'Text', 'Metric', ...
                'HorizontalAlignment', 'left');
            metricLabel.Layout.Row = 2;
            metricLabel.Layout.Column = 1;
            app.ValiditySweepMetricDropdown = uidropdown(sweepControlsGrid, ...
                'Items', { ...
                'worst_angle_deg', ...
                'max_abs_translation_delta_y', ...
                'worst_translation_delta_y', ...
                'worst_plane_refraction_delta_u', ...
                'worst_surface_vertex_delta_u', ...
                'worst_true_intersection_delta_u', ...
                'max_thinlens_deflection', ...
                'notice_count', ...
                'warning_count', ...
                'severe_count', ...
                'tir_count', ...
                'invalid_normal_count'}, ...
                'Value', 'max_abs_translation_delta_y', ...
                'ValueChangedFcn', @(~, ~) app.refreshValiditySweepPlot());
            app.ValiditySweepMetricDropdown.Layout.Row = 2;
            app.ValiditySweepMetricDropdown.Layout.Column = [2 4];

            updateSweepButton = uibutton(sweepControlsGrid, 'push', ...
                'Text', 'Update Validity Plot', ...
                'ButtonPushedFcn', @(~, ~) app.updateValidityFieldSweep());
            updateSweepButton.Layout.Row = 2;
            updateSweepButton.Layout.Column = [5 6];
            exportSweepButton = uibutton(sweepControlsGrid, 'push', ...
                'Text', 'Export Field Sweep CSV', ...
                'ButtonPushedFcn', @(~, ~) app.exportValidityFieldSweepCsv());
            exportSweepButton.Layout.Row = 2;
            exportSweepButton.Layout.Column = [7 8];

            validityTabs = uitabgroup(validityGrid);
            validityTabs.Layout.Row = 3;
            validityTabs.Layout.Column = 1;
            validityTablesTab = uitab(validityTabs, 'Title', 'Summary / Tables');
            validityTablesGrid = uigridlayout(validityTablesTab, [6 1]);
            validityTablesGrid.RowHeight = {22, 120, 22, '1x', 22, '1x'};
            validityTablesGrid.Padding = [8 8 8 8];
            validityTablesGrid.RowSpacing = 8;

            validitySummaryLabel = uilabel(validityTablesGrid, ...
                'Text', 'Ray warning summary', ...
                'FontWeight', 'bold');
            validitySummaryLabel.Layout.Row = 1;
            validitySummaryLabel.Layout.Column = 1;
            app.ValiditySummaryTable = uitable(validityTablesGrid);
            app.ValiditySummaryTable.Layout.Row = 2;
            app.ValiditySummaryTable.Layout.Column = 1;

            validitySegmentLabel = uilabel(validityTablesGrid, ...
                'Text', 'Segment translation and small-angle metrics', ...
                'FontWeight', 'bold');
            validitySegmentLabel.Layout.Row = 3;
            validitySegmentLabel.Layout.Column = 1;
            app.ValiditySegmentTable = uitable(validityTablesGrid);
            app.ValiditySegmentTable.Layout.Row = 4;
            app.ValiditySegmentTable.Layout.Column = 1;

            validityEventLabel = uilabel(validityTablesGrid, ...
                'Text', 'Event validity diagnostics', ...
                'FontWeight', 'bold');
            validityEventLabel.Layout.Row = 5;
            validityEventLabel.Layout.Column = 1;
            app.ValidityEventTable = uitable(validityTablesGrid);
            app.ValidityEventTable.Layout.Row = 6;
            app.ValidityEventTable.Layout.Column = 1;

            validityPlotTab = uitab(validityTabs, 'Title', 'Field Sweep Plot');
            validityPlotGrid = uigridlayout(validityPlotTab, [3 1]);
            validityPlotGrid.RowHeight = {24, '1x', 130};
            validityPlotGrid.Padding = [8 8 8 8];
            validityPlotGrid.RowSpacing = 8;
            app.ValiditySweepStatusLabel = uilabel(validityPlotGrid, ...
                'Text', 'Run Trace, then Update Validity Plot.', ...
                'FontColor', [0.2 0.42 0.2]);
            app.ValiditySweepStatusLabel.Layout.Row = 1;
            app.ValiditySweepStatusLabel.Layout.Column = 1;
            app.ValiditySweepAxes = uiaxes(validityPlotGrid);
            app.ValiditySweepAxes.Layout.Row = 2;
            app.ValiditySweepAxes.Layout.Column = 1;
            app.ValiditySweepTable = uitable(validityPlotGrid);
            app.ValiditySweepTable.Layout.Row = 3;
            app.ValiditySweepTable.Layout.Column = 1;

            chiefTab = uitab(app.TabGroup, 'Title', 'Chief / Marginal Rays');
            chiefGrid = uigridlayout(chiefTab, [3 1]);
            chiefGrid.RowHeight = {86, 130, '1x'};
            chiefGrid.Padding = [8 8 8 8];
            chiefGrid.RowSpacing = 8;
            app.ChiefTextArea = uitextarea(chiefGrid, ...
                'Editable', 'off', ...
                'FontName', 'Consolas');
            app.ChiefTextArea.Layout.Row = 1;
            app.ChiefTextArea.Layout.Column = 1;
            app.ChiefRayTable = uitable(chiefGrid);
            app.ChiefRayTable.Layout.Row = 2;
            app.ChiefRayTable.Layout.Column = 1;
            app.ChiefEventTable = uitable(chiefGrid);
            app.ChiefEventTable.Layout.Row = 3;
            app.ChiefEventTable.Layout.Column = 1;

            invariantTab = uitab(app.TabGroup, 'Title', 'Invariant / Phase Space');
            invariantGrid = uigridlayout(invariantTab, [3 1]);
            invariantGrid.RowHeight = {96, 130, '1x'};
            invariantGrid.Padding = [8 8 8 8];
            invariantGrid.RowSpacing = 8;
            app.InvariantTextArea = uitextarea(invariantGrid, ...
                'Editable', 'off', ...
                'FontName', 'Consolas');
            app.InvariantTextArea.Layout.Row = 1;
            app.InvariantTextArea.Layout.Column = 1;
            app.InvariantSummaryTable = uitable(invariantGrid);
            app.InvariantSummaryTable.Layout.Row = 2;
            app.InvariantSummaryTable.Layout.Column = 1;
            app.PhaseSpaceTable = uitable(invariantGrid);
            app.PhaseSpaceTable.Layout.Row = 3;
            app.PhaseSpaceTable.Layout.Column = 1;

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
            prescriptionGrid = uigridlayout(prescriptionTab, [1 1]);
            prescriptionGrid.ColumnWidth = {'1x'};
            prescriptionGrid.Padding = [8 8 8 8];

            prescriptionHelp = uitextarea(prescriptionGrid, ...
                'Editable', 'off', ...
                'FontName', 'Consolas', ...
                'Value', { ...
                'Prescription editing now lives in the Ray Diagram tab.'; ...
                ''; ...
                'Use the controls next to the table to add, duplicate, delete,'; ...
                'sort, check, and trace the active prescription.'; ...
                ''; ...
                'Use the File menu for CSV/MAT prescription import/export'; ...
                'and diagnostic exports.'; ...
                ''; ...
                'There is one editable prescription table in the app, so row'; ...
                'edits and element controls share the same dirty-state behavior.'});
            prescriptionHelp.Layout.Row = 1;
            prescriptionHelp.Layout.Column = 1;
        end

        function createMenus(app)
            fileMenu = uimenu(app.UIFigure, 'Text', 'File');
            uimenu(fileMenu, 'Text', 'New / Reset Default Prescription', ...
                'MenuSelectedFcn', @(~, ~) app.resetDefaults());
            uimenu(fileMenu, 'Text', 'Load Prescription CSV', ...
                'Separator', 'on', ...
                'MenuSelectedFcn', @(~, ~) app.loadPrescriptionCsv());
            uimenu(fileMenu, 'Text', 'Save Prescription CSV', ...
                'MenuSelectedFcn', @(~, ~) app.savePrescriptionCsv());
            uimenu(fileMenu, 'Text', 'Load Prescription MAT', ...
                'MenuSelectedFcn', @(~, ~) app.loadPrescriptionMat());
            uimenu(fileMenu, 'Text', 'Save Prescription MAT', ...
                'MenuSelectedFcn', @(~, ~) app.savePrescriptionMat());
            uimenu(fileMenu, 'Text', 'Export Ray Table CSV', ...
                'Separator', 'on', ...
                'MenuSelectedFcn', @(~, ~) app.exportRayTableCsv());
            uimenu(fileMenu, 'Text', 'Export Cardinal Data CSV', ...
                'MenuSelectedFcn', @(~, ~) app.exportCardinalDataCsv());
            uimenu(fileMenu, 'Text', 'Export Stop/Pupil Data CSV', ...
                'MenuSelectedFcn', @(~, ~) app.exportPupilDataCsv());
            uimenu(fileMenu, 'Text', 'Export Chief/Marginal Rays CSV', ...
                'MenuSelectedFcn', @(~, ~) app.exportChiefMarginalCsv());
            uimenu(fileMenu, 'Text', 'Export Invariant/Phase-Space CSV', ...
                'MenuSelectedFcn', @(~, ~) app.exportInvariantPhaseCsv());
            uimenu(fileMenu, 'Text', 'Export Vignetting CSV', ...
                'MenuSelectedFcn', @(~, ~) app.exportVignettingCsv());
            uimenu(fileMenu, 'Text', 'Export Paraxial Validity CSV', ...
                'MenuSelectedFcn', @(~, ~) app.exportParaxialValidityCsv());
            uimenu(fileMenu, 'Text', 'Export Combined First-Order Report TXT', ...
                'MenuSelectedFcn', @(~, ~) app.exportCombinedFirstOrderReportTxt());

            viewMenu = uimenu(app.UIFigure, 'Text', 'View');
            uimenu(viewMenu, 'Text', 'Show Ray Diagram', ...
                'MenuSelectedFcn', @(~, ~) app.selectTabByTitle("Ray Diagram"));
            uimenu(viewMenu, 'Text', 'Show System Matrix', ...
                'MenuSelectedFcn', @(~, ~) app.selectTabByTitle("System Matrix / Image Summary"));
            uimenu(viewMenu, 'Text', 'Show Cardinal / Gaussian', ...
                'MenuSelectedFcn', @(~, ~) app.selectTabByTitle("Cardinal / Gaussian"));
            uimenu(viewMenu, 'Text', 'Show Stops / Pupils', ...
                'MenuSelectedFcn', @(~, ~) app.selectTabByTitle("Stops / Pupils"));
            uimenu(viewMenu, 'Text', 'Show Vignetting', ...
                'MenuSelectedFcn', @(~, ~) app.selectTabByTitle("Vignetting"));
            uimenu(viewMenu, 'Text', 'Show Paraxial Validity', ...
                'MenuSelectedFcn', @(~, ~) app.selectTabByTitle("Paraxial Validity"));
            uimenu(viewMenu, 'Text', 'Show Equations', ...
                'MenuSelectedFcn', @(~, ~) app.selectTabByTitle("Equations"));
            uimenu(viewMenu, 'Text', 'Refresh Current View', ...
                'Separator', 'on', ...
                'MenuSelectedFcn', @(~, ~) app.refreshSelectedTab());

            helpMenu = uimenu(app.UIFigure, 'Text', 'Help');
            uimenu(helpMenu, 'Text', 'Conventions', ...
                'MenuSelectedFcn', @(~, ~) app.selectTabByTitle("Equations"));
            uimenu(helpMenu, 'Text', 'About N-Paraxial Surface App', ...
                'MenuSelectedFcn', @(~, ~) app.showAbout());
        end

        function selectTabByTitle(app, titleText)
            titleText = string(titleText);
            tabs = app.TabGroup.Children;
            for k = 1:numel(tabs)
                if string(tabs(k).Title) == titleText
                    if isequal(app.TabGroup.SelectedTab, tabs(k))
                        app.refreshSelectedTab();
                    else
                        app.TabGroup.SelectedTab = tabs(k);
                        drawnow limitrate
                        if app.LastRefreshedTabTitle ~= titleText
                            app.refreshSelectedTab();
                        end
                    end
                    return
                end
            end
            app.setStatus("View tab not found: " + titleText, true);
        end

        function showAbout(app)
            message = sprintf([ ...
                'YU_NParaxialSurface_App_V1\n\n', ...
                'Prescription-driven first-order y-u paraxial app.\n', ...
                'Use the Ray Diagram tab for prescription editing and the File menu for import/export.\n', ...
                'No exact Snell tracing, Seidel aberrations, or lithography optimization are included.']);
            uialert(app.UIFigure, message, 'About N-Paraxial Surface App');
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
                '   Ray vector: r = [y; u], where u is the paraxial ray angle in radians.'
                '   In this first-order model u is the small-angle slope coordinate;'
                '   no atan/tan reinterpretation or paraxial-validity correction is applied.'
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
                '   Diagnostic tables can be exported as CSV by diagnostic tab group.'
                '   Paraxial validity diagnostics can be exported as CSV.'
                '   A combined first-order diagnostics report can be exported as TXT.'
                '   Prescription editing lives in one authoritative Ray Diagram tab table.'
                '   The File menu handles prescription import/export and diagnostic export.'
                '   Diagnostic field y controls chief/marginal and invariant diagnostics.'
                '   Diagnostic field y also controls vignetting interval diagnostics.'
                '   Ray fan mode controls plotted ray sampling in the Ray Diagram tab.'
                '   Manual fixed-angle fan: u0 = linspace(-u_max, +u_max, nRays).'
                '   Aperture-limited admitted cone: u0 samples the final vignetting interval.'
                '   If the selected field is fully vignetted, no invalid fan is generated.'
                '   If the interval is unbounded, the app falls back to the manual fan.'
                '   Aperture-limited means geometrically admitted, not paraxial-valid.'
                '   Surface curves visually represent finite-radius spherical surfaces.'
                '   The first-segment penalty overlay compares y + d*u with y + d*tan(u).'
                '   Surface-angle schematics show u and incidence theta in degrees.'
                '   These graphical overlays do not affect tracing, clipping, matrices, image solve, or reports.'
                '   The Paraxial Validity tab can sweep field height and plot a selected validity metric.'
                '   Aperture-limited sweeps use the vignetting interval at each field point.'
                '   Field-sweep plotting is diagnostic-only and does not change optical calculations.'
                '   Milestones 2.3.3-2.3.5 include propagation penalty, small-angle metrics,'
                '   plane-refraction scalar diagnostics, thin-lens angle/deflection diagnostics,'
                '   vertex-plane spherical diagnostics, and local true-intersection diagnostics.'
                '   Exact-hit and exact-Snell results are not propagated downstream.'
                ''
                '9. System matrix chain'
                '   The System Matrix tab displays the final ABCD matrix and a matrix chain.'
                '   Chronological table rows propagate left-to-right through physical z.'
                '   Symbolic multiplication is right-to-left: later matrices multiply earlier states.'
                '   M = T(z_out-z_N)*E_N*...*E_1*T(z_1-z_obj).'
                '   Element matrices are L(f), S(n1,n2,R), or I for stop/dummy.'
                '   T(0) same-plane rows are retained to preserve event_order diagnostics.'
                ''
                '10. Cardinal / Gaussian diagnostics'
                '   For M = [A B; C D] from z1 to z2, n1 input and n2 output:'
                '   Delta = n1/n2'
                '   Phi = -n2*C'
                '   det(M) = A*D - B*C = n1/n2'
                '   If abs(C) > tol:'
                '   f_prime = -1/C'
                '   f = Delta/C'
                '   z_H1 = z1 + (D - Delta)/C'
                '   z_H2 = z2 + (1 - A)/C'
                '   z_F = z1 + D/C'
                '   z_Fp = z2 - A/C'
                '   FFD = D/C'
                '   BFD = -A/C'
                '   z_N1 = z1 + (D - 1)/C'
                '   z_N2 = z2 + (Delta - A)/C'
                '   If abs(C) <= tol, the system is reported as afocal/zero-power.'
                ''
                '11. Aperture stop and pupils'
                '   Finite aperture candidates constrain launch slopes by:'
                '   |A_i*y_obj + B_i*u0| <= a_i'
                '   The axial aperture stop is the tightest finite launch-slope interval.'
                '   Stop-targeted chief/marginal rays still use the selected axial stop.'
                '   Entrance pupil: z_EP = z_front + B_pre/A_pre, r_EP = a_stop/|A_pre|.'
                '   Exit pupil: x_XP = -B_post/D_post, z_XP = z_rear + x_XP.'
                '   The selected stop is split by event identity, not by z only.'
                ''
                '12. Off-axis vignetting intervals'
                '   For each finite aperture, compute the allowed u0 interval.'
                '   If abs(B_i) > tol:'
                '   u_low_i = min((-a_i - A_i*y_obj)/B_i, (a_i - A_i*y_obj)/B_i)'
                '   u_high_i = max((-a_i - A_i*y_obj)/B_i, (a_i - A_i*y_obj)/B_i)'
                '   If abs(B_i) <= tol, the interval is all slopes or empty.'
                '   The final unvignetted cone is the intersection of all intervals.'
                '   Lower and upper cone limits may be set by different apertures.'
                '   This is first-order meridional vignetting, not full 3D pupil analysis.'
                ''
                '13. Paraxial validity diagnostics'
                '   Diagnostic only: main tracing remains paraxial.'
                '   u is the paraxial ray angle in radians; no atan(u) reinterpretation is used.'
                '   Translation comparison: y2_p = y1 + d*u.'
                '   Exact-angle scalar comparison: y2_exact = y1 + d*tan(u).'
                '   Translation penalty: delta_y = d*(tan(u)-u).'
                '   Plane refraction comparison: u2_p = (n1/n2)*u1.'
                '   Exact scalar comparison: u2_exact = asin((n1/n2)*sin(u1)).'
                '   TIR diagnostic: abs((n1/n2)*sin(u1)) > 1 + tol.'
                '   Near-boundary Snell arguments may be clamped within tolerance.'
                '   Thin lenses have no unique exact Snell reference in this app.'
                '   Thin-lens validity reports u_in, deflection -y/f, and u_out.'
                '   Finite-radius spherical surfaces use alpha = -asin(y/R).'
                '   This vertex-plane diagnostic reduces to the paraxial surface matrix for small angles.'
                '   Local true-intersection diagnostics solve one local ray-sphere hit.'
                '   The exact hit and exact output angle are not propagated downstream.'
                '   Aperture clipping remains paraxial vertex-plane clipping.'
                ''
                '14. Chief, marginal, and invariant diagnostics'
                '   Chief ray targets y_stop = 0.'
                '   Upper and lower marginal rays target +a_stop and -a_stop.'
                '   These stop-targeted rays are distinct from vignetting interval limits.'
                '   r = [y;u] is not canonical when n changes.'
                '   Canonical momentum coordinate: p = n*u.'
                '   Lagrange invariant: H = n*(y1*u2 - y2*u1).'
                '   Raw y-u area is not expected to be conserved when n changes.'
                '   Invariant conservation is meaningful only where invariant_valid is true.'
                '   Event-plane invariant samples are labeled state_side = after_event.'
                ''
                '15. Image solve'
                '   Build M_ref = [A B; C D] from object plane to z_ref.'
                '   z_ref is the last enabled element position.'
                '   After translating by x: B_total = B + x*D.'
                '   The image condition is B_total = 0, so x = -B/D.'
                '   This milestone accepts only z_img >= z_ref.'
                ''
                '16. Current limitations'
                '   Paraxial first-order model only.'
                '   No exact Snell tracing in the main trace engine.'
                '   Finite-radius spherical surfaces include local true-intersection diagnostics.'
                '   These diagnostics are local and diagnostic-only, not a full exact ray trace.'
                '   Exact-hit and exact-output quantities are not propagated downstream.'
                '   Aperture clipping remains the main paraxial vertex-plane clipping.'
                '   No aberration calculation.'
                '   No advanced pupil diagnostics.'
                '   No full 3D pupil or field-of-view analysis.'
                '   No support yet for final image planes before the last enabled element.'
            };
        end

        function loadDefaults(app)
            app.ObjectZField.Value = -120;
            app.FieldMinField.Value = -5;
            app.FieldMaxField.Value = 5;
            app.FieldCountField.Value = 5;
            app.RayCountField.Value = 9;
            app.DiagnosticFieldField.Value = 0;
            if ~isempty(app.RayFanModeDropdown) && isvalid(app.RayFanModeDropdown)
                app.RayFanModeDropdown.Value = 'Manual fixed-angle fan';
            end
            if ~isempty(app.ManualUMaxField) && isvalid(app.ManualUMaxField)
                app.ManualUMaxField.Value = 0.04;
            end
            if ~isempty(app.PresetDropdown) && isvalid(app.PresetDropdown)
                app.PresetDropdown.Value = 'Two thin lenses';
            end
            app.PrescriptionTable.Data = nparaxial_default_prescription_yu();
            app.SelectedPrescriptionRows = [];
            app.Data = struct();
            app.IsDirty = true;
            app.IsValiditySweepDirty = true;
        end

        function resetDefaults(app)
            app.loadDefaults();
            app.markDirty("Defaults loaded.");
        end

        function loadSelectedPreset(app)
            try
                prescription = nparaxial_default_prescription_yu( ...
                    app.PresetDropdown.Value);
                app.PrescriptionTable.Data = table_to_prescription_yu(prescription);
                app.SelectedPrescriptionRows = [];
                app.markDirty("Loaded default prescription: " + ...
                    string(app.PresetDropdown.Value) + ".");
            catch ME
                app.setStatus("Error: " + string(ME.message), true);
            end
        end

        function checkPrescription(app)
            try
                prescription = table_to_prescription_yu(app.PrescriptionTable.Data);
                app.PrescriptionTable.Data = prescription;
                enabledCount = sum(prescription.enabled);
                app.markDirty(sprintf( ...
                    'Prescription OK: %d enabled element(s).', enabledCount));
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
                app.markDirty("Loaded prescription CSV: " + string(filename) + ".");
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
                app.markDirty("Loaded prescription MAT: " + string(filename) + ".");
            catch ME
                app.setStatus("Load MAT error: " + string(ME.message), true);
            end
        end

        function exportRayTableCsv(app)
            try
                if ~app.hasTraceData("Run Trace before exporting the ray table.")
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
                filename = nparaxial_export_table_csv_yu( ...
                    app.makeRayExportTable(), filename);
                app.setStatus("Exported ray table CSV: " + string(filename), false);
            catch ME
                app.setStatus("Export rays error: " + string(ME.message), true);
            end
        end

        function exportSummaryTxt(app)
            try
                if ~app.hasTraceData("Run Trace before exporting the summary.")
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
                lines = app.summaryExportLines();
                filename = nparaxial_export_summary_txt_yu(lines, filename);
                app.setStatus("Exported summary TXT: " + string(filename), false);
            catch ME
                app.setStatus("Export summary error: " + string(ME.message), true);
            end
        end

        function exportCardinalDataCsv(app)
            try
                if ~app.hasTraceData("Run Trace before exporting cardinal data.")
                    return
                end
                diag = app.Data.diagnostics;
                if isempty(diag.cardinal)
                    app.setStatus("Cardinal diagnostics are unavailable.", true);
                    return
                end
                app.exportTableCsvWithDialog( ...
                    diag.cardinal.table, ...
                    'nparaxial_cardinal.csv', ...
                    'Export Cardinal Data CSV', ...
                    'Exported cardinal data CSV');
            catch ME
                app.setStatus("Export cardinal error: " + string(ME.message), true);
            end
        end

        function exportPupilDataCsv(app)
            try
                if ~app.hasTraceData("Run Trace before exporting stop/pupil data.")
                    return
                end
                app.exportTableCsvWithDialog( ...
                    app.makePupilExportTable(), ...
                    'nparaxial_pupils.csv', ...
                    'Export Stop/Pupil Data CSV', ...
                    'Exported stop/pupil data CSV');
            catch ME
                app.setStatus("Export pupils error: " + string(ME.message), true);
            end
        end

        function exportChiefMarginalCsv(app)
            try
                if ~app.hasTraceData("Run Trace before exporting chief/marginal data.")
                    return
                end
                app.exportTableCsvWithDialog( ...
                    app.makeChiefMarginalExportTable(), ...
                    'nparaxial_chief_marginal.csv', ...
                    'Export Chief/Marginal Rays CSV', ...
                    'Exported chief/marginal rays CSV');
            catch ME
                app.setStatus("Export chief/marginal error: " + string(ME.message), true);
            end
        end

        function exportInvariantPhaseCsv(app)
            try
                if ~app.hasTraceData("Run Trace before exporting invariant/phase-space data.")
                    return
                end
                app.exportTableCsvWithDialog( ...
                    app.makeInvariantPhaseExportTable(), ...
                    'nparaxial_invariant_phase_space.csv', ...
                    'Export Invariant/Phase-Space CSV', ...
                    'Exported invariant/phase-space CSV');
            catch ME
                app.setStatus("Export invariant error: " + string(ME.message), true);
            end
        end

        function exportVignettingCsv(app)
            try
                if ~app.hasTraceData("Run Trace before exporting vignetting data.")
                    return
                end
                app.exportTableCsvWithDialog( ...
                    app.makeVignettingExportTable(), ...
                    'nparaxial_vignetting.csv', ...
                    'Export Vignetting CSV', ...
                    'Exported vignetting CSV');
            catch ME
                app.setStatus("Export vignetting error: " + string(ME.message), true);
            end
        end

        function exportParaxialValidityCsv(app)
            try
                if ~app.hasTraceData("Run Trace before exporting paraxial-validity data.")
                    return
                end
                app.exportTableCsvWithDialog( ...
                    app.makeParaxialValidityExportTable(), ...
                    'nparaxial_validity.csv', ...
                    'Export Paraxial Validity CSV', ...
                    'Exported paraxial-validity CSV');
            catch ME
                app.setStatus("Export paraxial validity error: " + ...
                    string(ME.message), true);
            end
        end

        function exportValidityFieldSweepCsv(app)
            try
                if ~app.hasTraceData("Run Trace before exporting validity field sweep.")
                    return
                end
                if app.IsValiditySweepDirty
                    app.setStatus( ...
                        "Update Validity Plot before exporting field sweep.", true);
                    return
                end
                if ~isfield(app.Data, 'validityFieldSweep') || ...
                        isempty(app.Data.validityFieldSweep) || ...
                        ~isfield(app.Data.validityFieldSweep, 'sweep_summary_table')
                    app.setStatus("Update Validity Plot before exporting field sweep.", true);
                    return
                end
                app.exportTableCsvWithDialog( ...
                    app.Data.validityFieldSweep.sweep_summary_table, ...
                    'nparaxial_validity_field_sweep.csv', ...
                    'Export Field Sweep CSV', ...
                    'Exported validity field sweep CSV');
            catch ME
                app.setStatus("Export validity field sweep error: " + ...
                    string(ME.message), true);
            end
        end

        function exportCombinedFirstOrderReportTxt(app)
            try
                if ~app.hasTraceData("Run Trace before exporting the first-order report.")
                    return
                end
                [fileName, pathName] = uiputfile( ...
                    {'*.txt', 'Text files (*.txt)'}, ...
                    'Export Combined First-Order Report TXT', ...
                    'nparaxial_first_order_report.txt');
                if isequal(fileName, 0)
                    app.setStatus("Export first-order report canceled.", false);
                    return
                end

                filename = fullfile(pathName, fileName);
                lines = nparaxial_combined_report_yu( ...
                    app.Data.prescription, app.Data.matrixTable, ...
                    app.Data.img, app.Data.diagnostics, app.Data.summaryLines);
                filename = nparaxial_export_summary_txt_yu(lines, filename);
                app.setStatus("Exported first-order report TXT: " + ...
                    string(filename), false);
            catch ME
                app.setStatus("Export first-order report error: " + ...
                    string(ME.message), true);
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
                app.IsDirty = false;
                app.IsValiditySweepDirty = true;
                app.PrescriptionTable.Data = data.prescription;
                app.refreshSelectedTab();
                app.setStatus(app.traceStatusMessage(data), false);
            catch ME
                app.IsDirty = true;
                app.clearResults();
                app.setStatus("Error: " + string(ME.message), true);
            end
        end

        function finishTrace(app)
            app.IsRunning = false;
        end

        function message = traceStatusMessage(~, data)
            message = "Trace complete.";
            if ~isfield(data, 'fieldTable') || isempty(data.fieldTable)
                return
            end
            T = data.fieldTable;
            if ismember('ray_fan_fully_vignetted', T.Properties.VariableNames) && ...
                    any(T.ray_fan_fully_vignetted)
                message = "Selected field is fully vignetted; no transmitted aperture-limited ray fan.";
                return
            end
            if ismember('ray_fan_fallback_used', T.Properties.VariableNames) && ...
                    any(T.ray_fan_fallback_used)
                message = "Trace complete. Aperture-limited interval is unbounded; using manual fixed-angle fan.";
            end
        end

        function requestTrace(app)
            app.markDirty("");
        end

        function refreshRayDiagramDisplay(app)
            if isempty(app.Data) || isempty(fieldnames(app.Data))
                app.setStatus("Overlay setting changed. Run Trace to draw ray diagram.", false);
                return
            end

            if string(app.TabGroup.SelectedTab.Title) == "Ray Diagram"
                app.plotRayDiagram();
            end
            app.setStatus("Ray diagram overlay display refreshed.", false);
        end

        function markDirty(app, reason)
            app.IsDirty = true;
            app.clearResults();
            message = "Inputs changed. Run Trace to refresh diagnostics.";
            if nargin >= 2 && strlength(string(reason)) > 0
                message = string(reason) + " " + message;
            end
            app.setStatus(message, false);
        end

        function clearResults(app)
            app.Data = struct();
            app.IsValiditySweepDirty = true;

            staleText = {'Inputs changed. Run Trace to refresh diagnostics.'};
            if ~isempty(app.RayAxes) && isvalid(app.RayAxes)
                cla(app.RayAxes);
                title(app.RayAxes, 'Run Trace to refresh diagnostics');
                xlabel(app.RayAxes, 'z');
                ylabel(app.RayAxes, 'y');
            end
            if ~isempty(app.SummaryTextArea) && isvalid(app.SummaryTextArea)
                app.SummaryTextArea.Value = staleText;
            end
            if ~isempty(app.MatrixTable) && isvalid(app.MatrixTable)
                app.MatrixTable.Data = table();
            end
            if ~isempty(app.FinalMatrixTextArea) && isvalid(app.FinalMatrixTextArea)
                app.FinalMatrixTextArea.Value = staleText;
            end
            if ~isempty(app.MatrixChainTextArea) && isvalid(app.MatrixChainTextArea)
                app.MatrixChainTextArea.Value = staleText;
            end
            if ~isempty(app.MatrixChainTable) && isvalid(app.MatrixChainTable)
                app.MatrixChainTable.Data = table();
            end
            if ~isempty(app.CardinalTextArea) && isvalid(app.CardinalTextArea)
                app.CardinalTextArea.Value = staleText;
            end
            if ~isempty(app.CardinalTable) && isvalid(app.CardinalTable)
                app.CardinalTable.Data = table();
            end
            if ~isempty(app.PupilTextArea) && isvalid(app.PupilTextArea)
                app.PupilTextArea.Value = staleText;
            end
            if ~isempty(app.PupilCandidateTable) && isvalid(app.PupilCandidateTable)
                app.PupilCandidateTable.Data = table();
            end
            if ~isempty(app.VignettingTextArea) && isvalid(app.VignettingTextArea)
                app.VignettingTextArea.Value = staleText;
            end
            if ~isempty(app.VignettingCandidateTable) && isvalid(app.VignettingCandidateTable)
                app.VignettingCandidateTable.Data = table();
            end
            if ~isempty(app.VignettingCumulativeTable) && isvalid(app.VignettingCumulativeTable)
                app.VignettingCumulativeTable.Data = table();
            end
            if ~isempty(app.ValidityTextArea) && isvalid(app.ValidityTextArea)
                app.ValidityTextArea.Value = staleText;
            end
            if ~isempty(app.ValiditySummaryTable) && isvalid(app.ValiditySummaryTable)
                app.ValiditySummaryTable.Data = table();
            end
            if ~isempty(app.ValiditySegmentTable) && isvalid(app.ValiditySegmentTable)
                app.ValiditySegmentTable.Data = table();
            end
            if ~isempty(app.ValidityEventTable) && isvalid(app.ValidityEventTable)
                app.ValidityEventTable.Data = table();
            end
            app.clearValiditySweepDisplay('Run Trace before field sweep');
            if ~isempty(app.ValiditySweepStatusLabel) && ...
                    isvalid(app.ValiditySweepStatusLabel)
                app.ValiditySweepStatusLabel.Text = ...
                    'Run Trace before updating validity field sweep.';
            end
            if ~isempty(app.ChiefTextArea) && isvalid(app.ChiefTextArea)
                app.ChiefTextArea.Value = staleText;
            end
            if ~isempty(app.ChiefRayTable) && isvalid(app.ChiefRayTable)
                app.ChiefRayTable.Data = table();
            end
            if ~isempty(app.ChiefEventTable) && isvalid(app.ChiefEventTable)
                app.ChiefEventTable.Data = table();
            end
            if ~isempty(app.InvariantTextArea) && isvalid(app.InvariantTextArea)
                app.InvariantTextArea.Value = staleText;
            end
            if ~isempty(app.InvariantSummaryTable) && isvalid(app.InvariantSummaryTable)
                app.InvariantSummaryTable.Data = table();
            end
            if ~isempty(app.PhaseSpaceTable) && isvalid(app.PhaseSpaceTable)
                app.PhaseSpaceTable.Data = table();
            end
        end

        function params = readParameters(app)
            params = struct();
            params.z_obj = app.ObjectZField.Value;
            params.y_min = app.FieldMinField.Value;
            params.y_max = app.FieldMaxField.Value;
            params.Nfield = round(app.FieldCountField.Value);
            params.Nrays = round(app.RayCountField.Value);
            params.y_diag = app.DiagnosticFieldField.Value;
            params.ray_fan_mode = string(app.RayFanModeDropdown.Value);
            params.manual_u_max = app.ManualUMaxField.Value;

            if ~isfinite(params.z_obj)
                error('Object plane z must be finite.');
            end
            if ~isfinite(params.y_min) || ~isfinite(params.y_max)
                error('Field min and max must be finite.');
            end
            if ~isfinite(params.y_diag)
                error('Diagnostic field height must be finite.');
            end
            if ~isfinite(params.manual_u_max) || params.manual_u_max <= 0
                error('Manual u max must be a positive finite value.');
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
            ray_fan_mode = strings(numel(yFields), 1);
            ray_fan_status = strings(numel(yFields), 1);
            ray_fan_u_low = NaN(numel(yFields), 1);
            ray_fan_u_high = NaN(numel(yFields), 1);
            ray_fan_fallback_used = false(numel(yFields), 1);
            ray_fan_fully_vignetted = false(numel(yFields), 1);
            ray_fan_lower_limiter = strings(numel(yFields), 1);
            ray_fan_upper_limiter = strings(numel(yFields), 1);

            for q = 1:numel(yFields)
                yObj = yFields(q);
                [rays, fanInfo] = app.makeRayFan( ...
                    params, prescription, img, yObj);
                if height(rays) > 0
                    rays.name = "field_" + string(q) + "_" + rays.name;
                    rays.ray_name = rays.name;
                    bundle = nparaxial_trace_bundle_yu( ...
                        rays, prescription, img.z_img);
                else
                    bundle = app.emptyTraceBundle();
                end
                diag = app.imageDiagnostics(bundle);

                bundleSet(q).field_index = q;
                bundleSet(q).y_obj = yObj;
                bundleSet(q).rays = rays;
                bundleSet(q).bundle = bundle;
                bundleSet(q).diag = diag;
                bundleSet(q).ray_fan_info = fanInfo;

                field_index(q) = q;
                y_object(q) = yObj;
                y_image_predicted(q) = img.m * yObj;
                y_image_measured(q) = diag.mean_yf;
                image_error(q) = diag.mean_yf - img.m*yObj;
                max_ray_spread(q) = diag.max_abs_delta_yf;
                rms_ray_spread(q) = diag.rms_delta_yf;
                num_passed(q) = sum(diag.table.traced);
                num_blocked(q) = sum(~diag.table.traced);
                ray_fan_mode(q) = fanInfo.sampling_mode;
                ray_fan_status(q) = fanInfo.status_text;
                ray_fan_u_low(q) = fanInfo.used_u_low;
                ray_fan_u_high(q) = fanInfo.used_u_high;
                ray_fan_fallback_used(q) = fanInfo.fallback_used;
                ray_fan_fully_vignetted(q) = fanInfo.fully_vignetted;
                ray_fan_lower_limiter(q) = fanInfo.lower_limiter_element_id;
                ray_fan_upper_limiter(q) = fanInfo.upper_limiter_element_id;
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
            fieldTable.ray_fan_mode = ray_fan_mode;
            fieldTable.ray_fan_status = ray_fan_status;
            fieldTable.ray_fan_u_low = ray_fan_u_low;
            fieldTable.ray_fan_u_high = ray_fan_u_high;
            fieldTable.ray_fan_fallback_used = ray_fan_fallback_used;
            fieldTable.ray_fan_fully_vignetted = ray_fan_fully_vignetted;
            fieldTable.ray_fan_lower_limiter = ray_fan_lower_limiter;
            fieldTable.ray_fan_upper_limiter = ray_fan_upper_limiter;

            matrixTable = app.makeMatrixTable(img, params.z_obj);
            matrixChain = nparaxial_matrix_chain_yu( ...
                prescription, params.z_obj, img.z_img);
            summaryLines = app.makeSummaryLines( ...
                params, prescription, img, primaryStop, fieldTable);
            diagnostics = app.computeFirstOrderDiagnostics( ...
                params, prescription, img);
            try
                diagnostics.paraxial_validity = ...
                    nparaxial_paraxial_validity_yu( ...
                    bundleSet, prescription, [], 1e-12);
                diagnostics.paraxial_validity_error = "";
            catch ME
                diagnostics.paraxial_validity = [];
                diagnostics.paraxial_validity_error = string(ME.message);
            end

            data = struct();
            data.params = params;
            data.prescription = prescription;
            data.enabledElements = nparaxial_enabled_elements_yu(prescription);
            data.img = img;
            data.yFields = yFields(:);
            data.primaryStop = primaryStop;
            data.bundleSet = bundleSet;
            data.fieldTable = fieldTable;
            data.rayFanLabel = params.ray_fan_mode;
            data.matrixTable = matrixTable;
            data.matrixChain = matrixChain;
            data.summaryLines = summaryLines;
            data.diagnostics = diagnostics;
        end

        function diagnostics = computeFirstOrderDiagnostics(~, params, prescription, img)
            diagnostics = nparaxial_field_diagnostics_yu( ...
                prescription, params.z_obj, img.z_img, params.y_diag);
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

        function [rays, fanInfo] = makeRayFan(~, params, prescription, img, yObj)
            switch string(params.ray_fan_mode)
                case "Aperture-limited admitted cone"
                    rays = nparaxial_make_aperture_limited_rays_yu( ...
                        prescription, params.z_obj, yObj, params.Nrays, ...
                        params.manual_u_max, 1e-12, img.z_img);
                otherwise
                    rays = nparaxial_make_manual_fan_rays_yu( ...
                        params.z_obj, yObj, params.Nrays, ...
                        params.manual_u_max);
            end
            fanInfo = rays.Properties.UserData;
        end

        function bundle = emptyTraceBundle(~)
            bundle = struct( ...
                'name', {}, ...
                'ray_in', {}, ...
                'res', {}, ...
                'trc', {}, ...
                'yf', {}, ...
                'uf', {});
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

        function ok = hasTraceData(app, message)
            ok = false;
            if app.IsDirty
                app.setStatus( ...
                    "Inputs changed. Run Trace to refresh diagnostics.", true);
                return
            end
            if isempty(app.Data) || isempty(fieldnames(app.Data))
                app.setStatus(message, true);
                return
            end
            ok = true;
        end

        function exportTableCsvWithDialog(app, T, defaultName, titleText, statusText)
            if ~istable(T) || isempty(T)
                app.setStatus("Diagnostic table is empty or unavailable.", true);
                return
            end

            [fileName, pathName] = uiputfile( ...
                {'*.csv', 'CSV files (*.csv)'}, titleText, defaultName);
            if isequal(fileName, 0)
                app.setStatus(string(titleText) + " canceled.", false);
                return
            end

            filename = fullfile(pathName, fileName);
            filename = nparaxial_export_table_csv_yu(T, filename);
            app.setStatus(string(statusText) + ": " + string(filename), false);
        end

        function lines = summaryExportLines(app)
            lines = string(app.Data.summaryLines(:));
            lines(end+1, 1) = "";
            lines(end+1, 1) = "System matrix / image table";
            lines(end+1, 1) = "---------------------------";
            matrixTable = app.Data.matrixTable;
            for k = 1:height(matrixTable)
                lines(end+1, 1) = sprintf('%s\t%.12g', ...
                    matrixTable.quantity(k), matrixTable.value(k)); %#ok<AGROW>
            end
        end

        function T = makePupilExportTable(app)
            diag = app.Data.diagnostics;
            if isempty(diag.stop)
                error('Stop/pupil diagnostics are unavailable.');
            end

            summary = table;
            summary.quantity = [
                "diagnostic_field_y"
                "field_label"
                "off_axis_warning"
                "selected_stop_element_id"
                "selected_stop_z"
                "selected_stop_aperture_radius"
            ];
            summary.value = [
                string(diag.diagnostic_field_y)
                string(diag.field_label)
                string(diag.off_axis_warning)
                string(diag.stop.selected_element_id)
                string(diag.stop.selected_z)
                string(diag.stop.selected_aperture_radius)
            ];

            T = app.flattenTableForExport(summary, "summary");
            T = [T; app.flattenTableForExport( ...
                diag.stop.candidate_table, "aperture_candidates")];
            if ~isempty(diag.pupil)
                T = [T; app.flattenTableForExport(diag.pupil.table, "pupil")];
            end
        end

        function T = makeChiefMarginalExportTable(app)
            diag = app.Data.diagnostics;
            if isempty(diag.chief_marginal)
                error('Chief/marginal diagnostics are unavailable.');
            end

            T = diag.chief_marginal.event_table;
            if isempty(T)
                T = diag.chief_marginal.ray_table;
            end
            diagnostic_field_y = repmat(diag.diagnostic_field_y, height(T), 1);
            field_label = repmat(diag.field_label, height(T), 1);
            off_axis_warning = repmat(diag.off_axis_warning, height(T), 1);
            T = addvars(T, diagnostic_field_y, field_label, off_axis_warning, ...
                'Before', 1);
        end

        function T = makeInvariantPhaseExportTable(app)
            diag = app.Data.diagnostics;
            if isempty(diag.invariant) && isempty(diag.phase_space)
                error('Invariant/phase-space diagnostics are unavailable.');
            end

            context = table;
            context.quantity = [
                "diagnostic_field_y"
                "field_label"
                "off_axis_warning"
                "note"
            ];
            noteText = "";
            if ~isempty(diag.invariant)
                noteText = strjoin(string(diag.invariant.note), "");
            end
            context.value = [
                string(diag.diagnostic_field_y)
                string(diag.field_label)
                string(diag.off_axis_warning)
                noteText
            ];

            T = app.flattenTableForExport(context, "context");
            if ~isempty(diag.invariant)
                T = [T; app.flattenTableForExport( ...
                    diag.invariant.summary, "invariant_summary")];
                T = [T; app.flattenTableForExport( ...
                    diag.invariant.table, "invariant_samples")];
            end
            if ~isempty(diag.phase_space)
                T = [T; app.flattenTableForExport( ...
                    diag.phase_space, "phase_space")];
            end
        end

        function T = makeVignettingExportTable(app)
            diag = app.Data.diagnostics;
            if ~isfield(diag, 'vignetting') || isempty(diag.vignetting)
                error('Vignetting diagnostics are unavailable.');
            end
            vig = diag.vignetting;
            if isfield(diag, 'vignetting_summary') && ...
                    ~isempty(diag.vignetting_summary)
                summary = diag.vignetting_summary;
            else
                summary = nparaxial_vignetting_summary_yu(vig);
            end

            T = app.flattenTableForExport( ...
                summary.table, "vignetting_summary");
            T = [T; app.flattenTableForExport( ...
                vig.candidate_table, "vignetting_candidates")];
            T = [T; app.flattenTableForExport( ...
                vig.cumulative_table, "vignetting_cumulative")];
        end

        function T = makeParaxialValidityExportTable(app)
            diag = app.Data.diagnostics;
            if ~isfield(diag, 'paraxial_validity') || ...
                    isempty(diag.paraxial_validity)
                error('Paraxial-validity diagnostics are unavailable.');
            end
            validity = diag.paraxial_validity;

            context = table;
            context.quantity = [
                "status_text"
                "ray_fan_mode"
                "diagnostic_field_y"
                "note"
            ];
            context.value = [
                string(validity.status_text)
                string(app.Data.rayFanLabel)
                string(diag.diagnostic_field_y)
                "Diagnostic only: main tracing remains paraxial."
            ];

            T = app.flattenTableForExport(context, "context");
            T = [T; app.flattenTableForExport( ...
                validity.threshold_table, "thresholds")];
            T = [T; app.flattenTableForExport( ...
                validity.summary_table, "validity_summary")];
            T = [T; app.flattenTableForExport( ...
                validity.segment_table, "validity_segments")];
            T = [T; app.flattenTableForExport( ...
                validity.event_table, "validity_events")];
        end

        function T = flattenTableForExport(app, sourceTable, sectionName)
            section = strings(0, 1);
            item = strings(0, 1);
            value = strings(0, 1);

            if istable(sourceTable) && ~isempty(sourceTable)
                names = string(sourceTable.Properties.VariableNames);
                for r = 1:height(sourceTable)
                    for c = 1:numel(names)
                        section(end+1, 1) = string(sectionName); %#ok<AGROW>
                        item(end+1, 1) = "row_" + string(r) + "." + names(c); %#ok<AGROW>
                        value(end+1, 1) = app.valueToString( ...
                            sourceTable.(names(c)), r); %#ok<AGROW>
                    end
                end
            end

            T = table(section, item, value);
        end

        function value = valueToString(~, columnData, row)
            if iscell(columnData)
                raw = columnData{row};
            else
                raw = columnData(row);
            end

            if isstring(raw) || ischar(raw)
                value = string(raw);
            elseif isnumeric(raw) || islogical(raw)
                value = string(raw);
            else
                value = "<unsupported>";
            end
            value = strjoin(value(:).', ",");
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
                sprintf('Ray fan mode = %s', params.ray_fan_mode)
                sprintf('Manual fixed-angle u max = %.6g rad', params.manual_u_max)
                sprintf('Passed rays = %d, blocked rays = %d', totalPassed, totalBlocked)
                sprintf('Max image error = %.3e', maxAbsError)
                sprintf('Max ray spread = %.3e', maxSpread)
                ''
                'Ray fan sampling'
                '----------------'
            };

            for q = 1:height(fieldTable)
                lines{end+1, 1} = sprintf( ...
                    'field %d y=%.6g: %s, u=[%.6g, %.6g], fallback=%d, fully_vignetted=%d', ...
                    fieldTable.field_index(q), fieldTable.y_object(q), ...
                    fieldTable.ray_fan_status(q), fieldTable.ray_fan_u_low(q), ...
                    fieldTable.ray_fan_u_high(q), fieldTable.ray_fan_fallback_used(q), ...
                    fieldTable.ray_fan_fully_vignetted(q)); %#ok<AGROW>
            end

            lines = [lines; {
                ''
                'Element sequence'
                '----------------'
                }];

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
                lines{end+1, 1} = 'No finite standalone stop was selected for stop-targeted diagnostics.';
            else
                lines{end+1, 1} = '';
                lines{end+1, 1} = sprintf( ...
                    'First finite standalone stop is "%s" at z = %.6g, radius = %.6g.', ...
                    primaryStop.element_id(1), primaryStop.z(1), ...
                    primaryStop.aperture_radius(1));
            end
        end

        function refreshSelectedTab(app)
            if isempty(app.Data) || isempty(fieldnames(app.Data))
                return
            end

            titleText = string(app.TabGroup.SelectedTab.Title);
            app.LastRefreshedTabTitle = titleText;
            switch titleText
                case "Ray Diagram"
                    app.plotRayDiagram();
                case "System Matrix / Image Summary"
                    app.updateSummary();
                case "Cardinal / Gaussian"
                    app.updateCardinalDiagnostics();
                case "Stops / Pupils"
                    app.updatePupilDiagnostics();
                case "Vignetting"
                    app.updateVignettingDiagnostics();
                case "Paraxial Validity"
                    app.updateParaxialValidityDiagnostics();
                case "Chief / Marginal Rays"
                    app.updateChiefMarginalDiagnostics();
                case "Invariant / Phase Space"
                    app.updateInvariantDiagnostics();
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
            legendHandles = gobjects(0, 1);
            legendNames = strings(0, 1);

            for q = 1:numel(data.bundleSet)
                bundle = data.bundleSet(q).bundle;
                rayStyles = app.rayStylesForBundle(data.bundleSet(q));
                for r = 1:numel(bundle)
                    res = bundle(r).res;
                    color = rayStyles.color(r, :);
                    width = rayStyles.line_width(r);
                    style = char(rayStyles.line_style(r));
                    displayName = char(rayStyles.display_name(r));
                    marker = char(rayStyles.marker(r));
                    for s = 1:numel(res.seg_z)
                        zSeg = res.seg_z{s};
                        ySeg = res.seg_y{s};
                        if numel(zSeg) < 2 || numel(ySeg) < 2
                            continue
                        end
                        hRay = plot(ax, zSeg, ySeg, ...
                            'Color', color, ...
                            'LineWidth', width, ...
                            'LineStyle', style, ...
                            'DisplayName', displayName);
                        legendHandles(end+1, 1) = hRay; %#ok<AGROW>
                        legendNames(end+1, 1) = string(displayName); %#ok<AGROW>
                        yVals = [yVals; ySeg(:)]; %#ok<AGROW>
                        zVals = [zVals; zSeg(:)]; %#ok<AGROW>
                    end
                    if ~bundle(r).trc && isfinite(res.blocked_at_z)
                        hClip = plot(ax, res.blocked_at_z, res.blocked_y, marker, ...
                            'Color', color, ...
                            'LineWidth', 1.5, ...
                            'MarkerSize', 7, ...
                            'DisplayName', 'Clipped ray');
                        legendHandles(end+1, 1) = hClip; %#ok<AGROW>
                        legendNames(end+1, 1) = "Clipped ray"; %#ok<AGROW>
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

            if app.surfaceCurvesEnabled()
                yFallback = max(abs(yLim));
                for k = 1:height(data.enabledElements)
                    element = data.enabledElements(k, :);
                    if element.type(1) == "surface" && isfinite(element.radius_R(1))
                        [zCurve, ~, ~] = nparaxial_surface_curve_points_yu( ...
                            element.z(1), element.radius_R(1), ...
                            element.aperture_radius(1), yFallback, 121, 1e-12);
                        zVals = [zVals; zCurve(:)]; %#ok<AGROW>
                    end
                end
            end

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

            if app.firstSegmentPenaltyEnabled()
                app.drawFirstSegmentPenaltyOverlay(ax, data);
            end
            if app.surfaceAngleSchematicEnabled()
                app.drawSurfaceAngleSchematicOverlay(ax, data);
            end

            xlabel(ax, 'z');
            ylabel(ax, 'y');
            title(ax, "N-element paraxial ray trace - " + data.rayFanLabel);
            [legendHandles, legendNames] = nparaxial_legend_unique_yu( ...
                legendHandles, legendNames);
            if isempty(legendHandles)
                legend(ax, 'off');
            else
                lgd = legend(ax, legendHandles, cellstr(legendNames), ...
                    'Location', 'best');
                lgd.Interpreter = 'none';
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
            if typeName == "surface" && app.surfaceCurvesEnabled()
                yFallback = max(abs(yLim));
                [zCurve, yCurve, curveInfo] = nparaxial_surface_curve_points_yu( ...
                    z, element.radius_R(1), a, yFallback, 121, 1e-12);
                if curveInfo.is_finite_surface && ~curveInfo.invalid_curve_flag
                    plot(ax, zCurve, yCurve, ...
                        'Color', color, ...
                        'LineStyle', '-', ...
                        'LineWidth', 1.8);
                    drewSurfaceCurve = true;
                elseif curveInfo.is_finite_surface
                    plot(ax, zCurve, yCurve, ...
                        'Color', color, ...
                        'LineStyle', '-', ...
                        'LineWidth', 1.4);
                    drewSurfaceCurve = true;
                end
            end

            if isfinite(a) && ~drewSurfaceCurve
                plot(ax, [z, z], [-a, a], ...
                    'Color', color, ...
                    'LineStyle', lineStyle, ...
                    'LineWidth', 2.0);
                plot(ax, z, a, 'v', 'Color', color, 'MarkerSize', 5);
                plot(ax, z, -a, '^', 'Color', color, 'MarkerSize', 5);
            else
                if ~drewSurfaceCurve
                    plot(ax, [z, z], yLim, ...
                        'Color', color, ...
                        'LineStyle', lineStyle, ...
                        'LineWidth', 1.1);
                end
            end

            if isfinite(a) && drewSurfaceCurve
                plot(ax, z, a, 'v', 'Color', color, 'MarkerSize', 5);
                plot(ax, z, -a, '^', 'Color', color, 'MarkerSize', 5);
            end

            text(ax, z, yLim(1), ...
                " " + element.element_id(1) + " (" + typeName + ")", ...
                'VerticalAlignment', 'bottom', ...
                'Color', color);
        end

        function drawFirstSegmentPenaltyOverlay(app, ax, data)
            if isempty(data.enabledElements)
                return
            end

            zFirst = data.enabledElements.z(1);
            overlay = nparaxial_first_segment_penalty_overlay_yu( ...
                data.bundleSet, data.params.z_obj, zFirst, 1e-12);
            validRows = overlay(overlay.valid_overlay, :);
            if isempty(validRows)
                if ~isempty(overlay)
                    app.setStatus(string(overlay.note(1)), false);
                end
                return
            end

            overlayColor = [0.35 0.35 0.35];
            markerColor = [0.2 0.2 0.2];
            maxLabeled = min(3, height(validRows));
            for k = 1:height(validRows)
                row = validRows(k, :);
                plot(ax, [row.z_start, row.z_end], ...
                    [row.y_exact_start, row.y_exact_end], ...
                    '--', 'Color', [0.62 0.62 0.62], ...
                    'LineWidth', 0.9);
                plot(ax, [row.z_end, row.z_end], ...
                    [row.y_paraxial_end, row.y_exact_end], ...
                    '-', 'Color', markerColor, 'LineWidth', 0.8);
                if k <= maxLabeled
                    text(ax, row.z_end, row.y_exact_end, ...
                        sprintf('  \\Deltay=%.3g, u=%.2f deg', ...
                        row.delta_y_first_segment, row.u_deg), ...
                        'Color', overlayColor, ...
                        'FontSize', 8, ...
                        'VerticalAlignment', 'middle');
                end
            end
        end

        function drawSurfaceAngleSchematicOverlay(~, ax, data)
            [eventRow, found] = firstFiniteSurfaceEventLocal(data);
            if ~found
                return
            end

            schematic = nparaxial_surface_angle_schematic_yu( ...
                eventRow.y_before(1), eventRow.u_before(1), ...
                eventRow.radius_R(1), 1e-12);
            if ~schematic.valid_schematic(1)
                return
            end

            xLim = xlim(ax);
            yLim = ylim(ax);
            z0 = eventRow.z(1);
            y0 = eventRow.y_before(1);
            scale = 0.10*min(diff(xLim), diff(yLim));
            if ~isfinite(scale) || scale <= 0
                scale = 1;
            end

            u = eventRow.u_before(1);
            alpha = schematic.alpha(1);
            normalColor = [0.25 0.25 0.25];
            rayColor = [0.1 0.25 0.65];
            axisColor = [0.25 0.25 0.25];

            plot(ax, [z0 - scale, z0 + scale], [y0, y0], ...
                ':', 'Color', axisColor, 'LineWidth', 0.8);
            plot_angle_line_local(ax, z0, y0, u, scale, rayColor, '-');
            plot_angle_line_local(ax, z0, y0, alpha, scale, normalColor, '--');
            plot_arc_local(ax, z0, y0, 0, u, 0.42*scale, rayColor);
            plot_arc_local(ax, z0, y0, alpha, u, 0.62*scale, normalColor);

            text(ax, z0 + 0.15*scale, y0 + 0.85*scale, ...
                sprintf('vertex-plane surface-angle schematic\\nu=%.2f deg, \\theta=%.2f deg', ...
                schematic.u_deg(1), schematic.theta_deg(1)), ...
                'Color', normalColor, ...
                'FontSize', 8, ...
                'VerticalAlignment', 'bottom');
        end

        function tf = surfaceCurvesEnabled(app)
            tf = ~isempty(app.SurfaceCurvesCheckBox) && ...
                isvalid(app.SurfaceCurvesCheckBox) && app.SurfaceCurvesCheckBox.Value;
        end

        function tf = firstSegmentPenaltyEnabled(app)
            tf = ~isempty(app.FirstSegmentPenaltyCheckBox) && ...
                isvalid(app.FirstSegmentPenaltyCheckBox) && ...
                app.FirstSegmentPenaltyCheckBox.Value;
        end

        function tf = surfaceAngleSchematicEnabled(app)
            tf = ~isempty(app.SurfaceAngleSchematicCheckBox) && ...
                isvalid(app.SurfaceAngleSchematicCheckBox) && ...
                app.SurfaceAngleSchematicCheckBox.Value;
        end

        function styles = rayStylesForBundle(~, bundleSetItem)
            bundle = bundleSetItem.bundle;
            nRays = numel(bundle);
            if nRays == 0
                styles = table( ...
                    strings(0, 1), zeros(0, 3), strings(0, 1), ...
                    strings(0, 1), strings(0, 1), zeros(0, 1), ...
                    'VariableNames', {'role', 'color', 'line_style', ...
                    'display_name', 'marker', 'line_width'});
                return
            end

            clipped = ~[bundle.trc].';
            if isfield(bundleSetItem, 'rays') && istable(bundleSetItem.rays) && ...
                    height(bundleSetItem.rays) == nRays
                styles = nparaxial_ray_role_style_yu( ...
                    bundleSetItem.rays, clipped);
                return
            end

            rayNames = strings(nRays, 1);
            for k = 1:nRays
                rayNames(k) = string(bundle(k).name);
            end
            rayTable = table(rayNames, 'VariableNames', {'name'});
            styles = nparaxial_ray_role_style_yu(rayTable, clipped);
        end

        function [color, width, style, displayName, marker] = ...
                rayStyle(~, rayInfo, isBlocked)
            [color, style, displayName, marker, width] = ...
                nparaxial_ray_role_style_yu(rayInfo, isBlocked);
        end

        function updateSummary(app)
            app.SummaryTextArea.Value = app.Data.summaryLines;
            app.MatrixTable.Data = app.Data.matrixTable;

            if isfield(app.Data, 'matrixChain') && ~isempty(app.Data.matrixChain)
                chain = app.Data.matrixChain;
                app.MatrixChainTextArea.Value = cellstr( ...
                    nparaxial_matrix_chain_text_yu(chain));
                app.MatrixChainTable.Data = chain.steps;
                app.FinalMatrixTextArea.Value = cellstr( ...
                    nparaxial_matrix_to_text_yu( ...
                    chain.final_matrix, 'Final cumulative M'));
            else
                app.MatrixChainTextArea.Value = { ...
                    'Run Trace to build the matrix-chain view.'};
                app.MatrixChainTable.Data = table();
                app.FinalMatrixTextArea.Value = { ...
                    'Final cumulative M unavailable.'};
            end
        end

        function updateCardinalDiagnostics(app)
            diag = app.Data.diagnostics;
            if strlength(diag.cardinal_error) > 0
                app.CardinalTextArea.Value = { ...
                    'Cardinal diagnostics failed.'; ...
                    char(diag.cardinal_error)};
                app.CardinalTable.Data = table();
                return
            end

            card = diag.cardinal;
            app.CardinalTextArea.Value = {
                'Cardinal / Gaussian diagnostics'
                '-------------------------------'
                sprintf('Reference planes: z1 = %.6g, z2 = %.6g', card.z1, card.z2)
                sprintf('Object/image media: n1 = %.6g, n2 = %.6g', card.n1, card.n2)
                sprintf('Classification: %s', card.classification)
                sprintf('Phi = %.6g', card.Phi)
                sprintf('det(M) = %.12g, expected n1/n2 = %.12g, error = %.3e', ...
                    card.determinant, card.expected_determinant, ...
                    card.determinant_error)
                };
            app.CardinalTable.Data = card.table;
        end

        function updatePupilDiagnostics(app)
            diag = app.Data.diagnostics;
            if strlength(diag.stop_error) > 0
                app.PupilTextArea.Value = { ...
                    'Aperture-stop diagnostics failed.'; ...
                    char(diag.stop_error)};
                app.PupilCandidateTable.Data = table();
                return
            end
            if isempty(diag.stop) || ~diag.stop.has_stop
                note = "No finite aperture stop candidate was selected.";
                if ~isempty(diag.stop)
                    note = diag.stop.note;
                    app.PupilCandidateTable.Data = diag.stop.candidate_table;
                else
                    app.PupilCandidateTable.Data = table();
                end
                app.PupilTextArea.Value = cellstr(note);
                return
            end

            stopDiag = diag.stop;
            lines = {
                'Stops / Pupils diagnostics'
                '--------------------------'
                'Aperture-stop selection is axial-first-order in this milestone.'
                sprintf('Diagnostic field height y = %.6g', diag.diagnostic_field_y)
                sprintf('Field label: %s', diag.field_label)
                sprintf('Selected aperture stop: %s at z = %.6g, radius = %.6g', ...
                    stopDiag.selected_element_id, stopDiag.selected_z, ...
                    stopDiag.selected_aperture_radius)
                sprintf('Selection rule: %s', stopDiag.note)
                };
            if isfield(stopDiag, 'off_axis_warning') && ...
                    strlength(stopDiag.off_axis_warning) > 0
                lines{end+1, 1} = char(stopDiag.off_axis_warning);
            end

            if strlength(diag.pupil_error) > 0
                lines{end+1, 1} = ['Pupil diagnostics failed: ', ...
                    char(diag.pupil_error)];
            elseif ~isempty(diag.pupil)
                pupil = diag.pupil;
                lines = [lines; {
                    sprintf('Entrance pupil z = %.6g, radius = %.6g, m = %.6g', ...
                        pupil.z_EP, pupil.r_EP, pupil.m_EP)
                    sprintf('Exit pupil z = %.6g, radius = %.6g, m = %.6g', ...
                        pupil.z_XP, pupil.r_XP, pupil.m_XP)
                    sprintf('Pre-stop events = %s', mat2str(pupil.pre_event_indices.'))
                    sprintf('Post-stop events = %s', mat2str(pupil.post_event_indices.'))
                    }];
            end

            app.PupilTextArea.Value = lines;
            app.PupilCandidateTable.Data = stopDiag.candidate_table;
        end

        function updateVignettingDiagnostics(app)
            diag = app.Data.diagnostics;
            if ~isfield(diag, 'vignetting') || isempty(diag.vignetting) || ...
                    strlength(diag.vignetting_error) > 0
                app.VignettingTextArea.Value = { ...
                    'Vignetting interval diagnostics'
                    '--------------------------------'
                    sprintf('Diagnostic field height y = %.6g', diag.diagnostic_field_y)
                    char("Vignetting diagnostics unavailable: " + ...
                    diag.vignetting_error)
                    };
                app.VignettingCandidateTable.Data = table();
                app.VignettingCumulativeTable.Data = table();
                return
            end

            summary = diag.vignetting_summary;
            lines = string(summary.lines(:));
            if diag.is_axial
                lines(end+1, 1) = "Diagnostic field is axial.";
            else
                lines(end+1, 1) = string(diag.off_axis_warning);
            end
            lines(end+1, 1) = ...
                "Stop-targeted chief/marginal rays remain separate from vignetting interval limits.";

            app.VignettingTextArea.Value = cellstr(lines);
            app.VignettingCandidateTable.Data = diag.vignetting.candidate_table;
            app.VignettingCumulativeTable.Data = diag.vignetting.cumulative_table;
        end

        function updateParaxialValidityDiagnostics(app)
            diag = app.Data.diagnostics;
            if ~isfield(diag, 'paraxial_validity') || ...
                    isempty(diag.paraxial_validity) || ...
                    (isfield(diag, 'paraxial_validity_error') && ...
                    strlength(diag.paraxial_validity_error) > 0)
                message = "";
                if isfield(diag, 'paraxial_validity_error')
                    message = diag.paraxial_validity_error;
                end
                app.ValidityTextArea.Value = { ...
                    'Paraxial validity diagnostics'
                    '-----------------------------'
                    'Diagnostic only: main tracing remains paraxial.'
                    'u is the paraxial ray angle in radians.'
                    char("Diagnostics unavailable: " + message)
                    };
                app.ValiditySummaryTable.Data = table();
                app.ValiditySegmentTable.Data = table();
                app.ValidityEventTable.Data = table();
                return
            end

            validity = diag.paraxial_validity;
            worstLevel = "ok";
            raysEvaluated = 0;
            if ~isempty(validity.summary_table)
                raysEvaluated = height(validity.summary_table);
                worstLevel = app.maxWarningLevel( ...
                    validity.summary_table.worst_warning_level);
            end
            lines = {
                'Paraxial validity diagnostics'
                '-----------------------------'
                'Diagnostic only: main tracing remains paraxial.'
                'u is the paraxial ray angle in radians; no atan(u) reinterpretation is used.'
                sprintf('Ray fan mode: %s', app.Data.rayFanLabel)
                sprintf('Diagnostic field height y = %.6g', diag.diagnostic_field_y)
                sprintf('Rays evaluated = %d', raysEvaluated)
                sprintf('Worst warning level = %s', worstLevel)
                'Aperture-limited means admitted by apertures, not paraxial-valid.'
                'Field-sweep range, mode, and point-count changes invalidate only the stored sweep.'
                'Metric changes redraw the current stored sweep without recomputing.'
                'Finite-radius spherical surfaces include a local true-intersection diagnostic.'
                'It solves one local ray-sphere hit from the paraxial event state.'
                'The exact hit and exact output angle are not propagated downstream.'
                'Vertex-plane scalar quantities use y_before at the vertex plane.'
                'True-intersection quantities are local diagnostics only.'
                'Thresholds: ok <=0.05 rad and rel tan error <1e-3; notice <=0.10 rad or <5e-3; warning <=0.20 rad or <2e-2; severe otherwise, TIR, invalid asin, tan singularity, or nonfinite values.'
                ''
                };
            lines = [lines; cellstr(validity.note(:))];
            app.ValidityTextArea.Value = lines;
            app.ValiditySummaryTable.Data = validity.summary_table;
            app.ValiditySegmentTable.Data = validity.segment_table;
            app.ValidityEventTable.Data = validity.event_table;
            if ~app.IsValiditySweepDirty && ...
                    isfield(app.Data, 'validityFieldSweep') && ...
                    ~isempty(app.Data.validityFieldSweep)
                app.ValiditySweepTable.Data = ...
                    app.Data.validityFieldSweep.sweep_summary_table;
                app.refreshValiditySweepPlot();
            end
        end

        function noteValiditySweepControlsChanged(app)
            app.invalidateValiditySweep( ...
                "Field-sweep controls changed. Press Update Validity Plot to recompute.");
        end

        function invalidateValiditySweep(app, message)
            app.IsValiditySweepDirty = true;
            if ~isempty(app.Data) && isstruct(app.Data) && ...
                    isfield(app.Data, 'validityFieldSweep')
                app.Data = rmfield(app.Data, 'validityFieldSweep');
            end
            app.clearValiditySweepDisplay('Update Validity Plot to refresh field sweep');
            app.setValiditySweepStatus( ...
                message, false);
        end

        function clearValiditySweepDisplay(app, plotTitle)
            if ~isempty(app.ValiditySweepAxes) && isvalid(app.ValiditySweepAxes)
                cla(app.ValiditySweepAxes);
                grid(app.ValiditySweepAxes, 'on');
                box(app.ValiditySweepAxes, 'on');
                title(app.ValiditySweepAxes, plotTitle);
                xlabel(app.ValiditySweepAxes, 'Field height y_{field}');
                ylabel(app.ValiditySweepAxes, 'metric');
            end
            if ~isempty(app.ValiditySweepTable) && isvalid(app.ValiditySweepTable)
                app.ValiditySweepTable.Data = table();
            end
        end

        function updateValidityFieldSweep(app)
            try
                if ~app.hasTraceData("Run Trace before updating validity field-sweep plot.")
                    return
                end

                fieldHeights = app.validitySweepFieldHeights();
                rayFanSettings = struct();
                rayFanSettings.mode = string(app.RayFanModeDropdown.Value);
                rayFanSettings.n_rays = round(app.RayCountField.Value);
                rayFanSettings.manual_u_max = app.ManualUMaxField.Value;
                validitySettings = struct('z_final', app.Data.img.z_img);

                app.setValiditySweepStatus("Computing validity field sweep...", false);
                drawnow limitrate

                sweep = nparaxial_validity_field_sweep_yu( ...
                    app.Data.prescription, app.Data.params.z_obj, ...
                    fieldHeights, rayFanSettings, validitySettings, 1e-12);
                app.Data.validityFieldSweep = sweep;
                app.IsValiditySweepDirty = false;
                app.ValiditySweepTable.Data = sweep.sweep_summary_table;
                app.refreshValiditySweepPlot();
                app.setStatus("Updated paraxial-validity field sweep.", false);
            catch ME
                app.IsValiditySweepDirty = true;
                if ~isempty(app.Data) && isstruct(app.Data) && ...
                        isfield(app.Data, 'validityFieldSweep')
                    app.Data = rmfield(app.Data, 'validityFieldSweep');
                end
                app.clearValiditySweepDisplay('Update Validity Plot to refresh field sweep');
                app.setValiditySweepStatus("Field sweep error: " + string(ME.message), true);
                app.setStatus("Field sweep error: " + string(ME.message), true);
            end
        end

        function fields = validitySweepFieldHeights(app)
            mode = string(app.ValiditySweepModeDropdown.Value);
            n = max(1, round(app.ValiditySweepCountField.Value));
            app.ValiditySweepCountField.Value = n;

            switch mode
                case "Current field only"
                    fields = app.DiagnosticFieldField.Value;
                case "Symmetric field sweep"
                    extent = max(abs([app.DiagnosticFieldField.Value, ...
                        app.FieldMinField.Value, app.FieldMaxField.Value]));
                    if ~isfinite(extent) || extent <= 0
                        extent = 10;
                    end
                    app.ValiditySweepFieldMinField.Value = -extent;
                    app.ValiditySweepFieldMaxField.Value = extent;
                    fields = linspace(-extent, extent, n);
                otherwise
                    yMin = app.ValiditySweepFieldMinField.Value;
                    yMax = app.ValiditySweepFieldMaxField.Value;
                    if ~isfinite(yMin) || ~isfinite(yMax)
                        error('Field sweep min and max must be finite.');
                    end
                    if yMin > yMax
                        error('Field sweep min must be <= field sweep max.');
                    end
                    fields = linspace(yMin, yMax, n);
            end
            fields = fields(:);
        end

        function refreshValiditySweepPlot(app)
            if isempty(app.ValiditySweepAxes) || ~isvalid(app.ValiditySweepAxes)
                return
            end
            app.clearValiditySweepDisplay('Paraxial validity field sweep');
            metric = string(app.ValiditySweepMetricDropdown.Value);
            ylabel(app.ValiditySweepAxes, char(metric), 'Interpreter', 'none');
            title(app.ValiditySweepAxes, 'Paraxial validity field sweep');

            if app.IsValiditySweepDirty
                app.setValiditySweepStatus( ...
                    "Press Update Validity Plot to compute a field sweep.", false);
                return
            end
            if isempty(app.Data) || ~isfield(app.Data, 'validityFieldSweep') || ...
                    isempty(app.Data.validityFieldSweep)
                app.setValiditySweepStatus( ...
                    "Press Update Validity Plot to compute a field sweep.", false);
                return
            end

            T = app.Data.validityFieldSweep.sweep_summary_table;
            [y, metricStatus] = nparaxial_validity_field_sweep_metric_yu(T, metric);
            if metricStatus ~= "Metric available."
                app.ValiditySweepTable.Data = T;
                app.setValiditySweepStatus(metricStatus, true);
                return
            end

            x = T.y_field;
            plot(app.ValiditySweepAxes, x, y, '-o', ...
                'LineWidth', 1.2, ...
                'MarkerSize', 5);
            app.ValiditySweepTable.Data = T;

            if all(~isfinite(y))
                app.setValiditySweepStatus( ...
                    "All values for selected field-sweep metric are NaN or unavailable.", true);
            else
                app.setValiditySweepStatus( ...
                    "Field sweep plotted: " + metric + " versus field height.", false);
            end
        end

        function setValiditySweepStatus(app, message, isError)
            if isempty(app.ValiditySweepStatusLabel) || ...
                    ~isvalid(app.ValiditySweepStatusLabel)
                return
            end
            app.ValiditySweepStatusLabel.Text = char(message);
            if isError
                app.ValiditySweepStatusLabel.FontColor = [0.72 0.12 0.12];
            else
                app.ValiditySweepStatusLabel.FontColor = [0.2 0.42 0.2];
            end
        end

        function updateChiefMarginalDiagnostics(app)
            diag = app.Data.diagnostics;
            if strlength(diag.chief_error) > 0 || isempty(diag.chief_marginal)
                app.ChiefTextArea.Value = { ...
                    'Chief / marginal diagnostics'
                    '----------------------------'
                    sprintf('Diagnostic field height y = %.6g', diag.diagnostic_field_y)
                    sprintf('Field label: %s', diag.field_label)
                    'Rays are traced for the selected diagnostic field height; aperture stop selection remains axial.'
                    char(diag.off_axis_warning)
                    char("Chief/marginal diagnostics unavailable: " + diag.chief_error)
                    };
                app.ChiefRayTable.Data = table( ...
                    "Chief/marginal diagnostics unavailable: " + ...
                    diag.chief_error, ...
                    'VariableNames', {'message'});
                app.ChiefEventTable.Data = table();
                return
            end

            stopEvent = diag.chief_marginal.stop_event;
            app.ChiefTextArea.Value = {
                'Chief / marginal diagnostics'
                '----------------------------'
                sprintf('Diagnostic field height y = %.6g', diag.diagnostic_field_y)
                sprintf('Field label: %s', diag.field_label)
                'Rays are traced for the selected diagnostic field height; aperture stop selection remains axial.'
                char(diag.off_axis_warning)
                sprintf('Selected stop: %s (%s), z = %.6g, radius = %.6g', ...
                    stopEvent.element_id(1), stopEvent.type(1), ...
                    stopEvent.z(1), stopEvent.aperture_radius(1))
                };
            app.ChiefRayTable.Data = diag.chief_marginal.ray_table;
            app.ChiefEventTable.Data = diag.chief_marginal.event_table;
        end

        function updateInvariantDiagnostics(app)
            diag = app.Data.diagnostics;
            if strlength(diag.invariant_error) > 0 || isempty(diag.invariant)
                app.InvariantTextArea.Value = { ...
                'Invariant / phase-space diagnostics'
                '-----------------------------------'
                sprintf('Diagnostic field height y = %.6g', diag.diagnostic_field_y)
                sprintf('Field label: %s', diag.field_label)
                'Invariant uses canonical p = n*u.'
                'Rays are traced for the selected diagnostic field height; aperture stop selection remains axial.'
                'Raw y-u area is not conserved across refractive-index changes.'
                'Invariant conservation is meaningful only where invariant_valid is true.'
                char(diag.off_axis_warning)
                    char("Invariant diagnostics unavailable: " + diag.invariant_error)
                    };
                app.InvariantSummaryTable.Data = table( ...
                    "Invariant diagnostics unavailable: " + ...
                    diag.invariant_error, ...
                    'VariableNames', {'message'});
                app.PhaseSpaceTable.Data = diag.phase_space;
                return
            end

            stopText = 'Selected stop unavailable.';
            if ~isempty(diag.stop) && diag.stop.has_stop
                stopType = diag.stop.selected_event.type(1);
                stopText = sprintf('Selected stop: %s (%s), z = %.6g', ...
                    diag.stop.selected_element_id, stopType, ...
                    diag.stop.selected_z);
            end
            app.InvariantTextArea.Value = {
                'Invariant / phase-space diagnostics'
                '-----------------------------------'
                sprintf('Diagnostic field height y = %.6g', diag.diagnostic_field_y)
                sprintf('Field label: %s', diag.field_label)
                'Rays are traced for the selected diagnostic field height; aperture stop selection remains axial.'
                char(diag.off_axis_warning)
                stopText
                'Invariant uses canonical p = n*u.'
                'Raw y-u area is not conserved across refractive-index changes.'
                'Samples at event planes are after-event states.'
                'Conservation is meaningful only where invariant_valid is true.'
                };
            app.InvariantSummaryTable.Data = diag.invariant.summary;
            app.PhaseSpaceTable.Data = diag.phase_space;
        end

        function level = maxWarningLevel(~, levels)
            levels = string(levels(:));
            scores = zeros(numel(levels), 1);
            scores(levels == "notice") = 1;
            scores(levels == "warning") = 2;
            scores(levels == "severe") = 3;
            names = ["ok"; "notice"; "warning"; "severe"];
            if isempty(scores)
                level = "ok";
            else
                level = names(max(scores) + 1);
            end
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


function [eventRow, found] = firstFiniteSurfaceEventLocal(data)
    eventRow = table();
    found = false;
    if ~isfield(data, 'bundleSet')
        return
    end

    for q = 1:numel(data.bundleSet)
        bundle = data.bundleSet(q).bundle;
        for r = 1:numel(bundle)
            events = bundle(r).res.events;
            if isempty(events)
                continue
            end
            mask = events.type == "surface" & isfinite(events.radius_R) & ...
                events.passed_aperture;
            idx = find(mask, 1, 'first');
            if ~isempty(idx)
                eventRow = events(idx, :);
                found = true;
                return
            end
        end
    end
end


function plot_angle_line_local(ax, z0, y0, angle, scale, color, style)
    dz = scale*cos(angle);
    dy = scale*sin(angle);
    plot(ax, [z0 - dz, z0 + dz], [y0 - dy, y0 + dy], ...
        style, 'Color', color, 'LineWidth', 1.0);
end


function plot_arc_local(ax, z0, y0, angle1, angle2, radius, color)
    if ~isfinite(angle1) || ~isfinite(angle2) || ~isfinite(radius) || radius <= 0
        return
    end
    n = 32;
    theta = linspace(angle1, angle2, n);
    z = z0 + radius*cos(theta);
    y = y0 + radius*sin(theta);
    plot(ax, z, y, '-', 'Color', color, 'LineWidth', 0.8);
end
