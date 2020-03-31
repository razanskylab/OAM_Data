% file      Export_Native_Map.m
% author    Johannes Rebling
% date      28. Nov 2017

% export M.xy, i.e. the map data in full native resolution to an RGB image file
% using the colormap specified in Map.colorMap

function Export_Native_Map(M)

  % Check for existing file before exporting and ask user what to do?
  if isempty(M.xy)
    short_warn('Cannot export map, need to define M.xy first!');
    return;
  end
  fprintf('Exporting native resolution maps: \n')

  name_wo_ext = [M.Path.folder M.Path.name];

  % Check if folder exists
  [M.Path.folder, ~] = check_folder_existance(M.Path.folder,0);
  if M.exportRawTiff
    fprintf('  raw tiff...\n');
    M.Path.extention = '.tiff';
    fullPath = [name_wo_ext M.Path.extention];
    [exportPath] = check_exisiting_file(fullPath,0);
    useFullRange = true;
    export_raw_maps(M.xy,M.colorMap,exportPath,useFullRange)
  end

  if M.exportRawPng
    fprintf('  raw png...\n');
    M.Path.extention = '.png';
    fullPath = [name_wo_ext M.Path.extention];
    [exportPath] = check_exisiting_file(fullPath,0);
    useFullRange = true;
    export_raw_maps(M.xy,M.colorMap,exportPath,useFullRange)
  end

  % Export
  if ~M.exportRawPng && ~M.exportRawTiff
    fprintf('   tumble weed...nothing exported...');
  end

  % Display that procedure is over
  done();

  % Open folder is we are running pc
  if (M.openExportFolder && ispc)
    winopen(M.Path.folder);
  end
end
