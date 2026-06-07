function app = demo_launch_v2_lightweight_system_viewer_yu()
%DEMO_LAUNCH_V2_LIGHTWEIGHT_SYSTEM_VIEWER_YU Launch the lightweight V2 app.

    rootFolder = fileparts(fileparts(mfilename('fullpath')));
    addpath(rootFolder);
    addpath(fullfile(rootFolder, 'core'));
    addpath(fullfile(rootFolder, 'workflows'));

    app = YU_NParaxialSurface_App_V2();
    if nargout == 0
        clear app
    end
end
