% file      Export_figures.m
% author    Johannes Rebling
% date      28. Nov 2017

% Function used to export / save all the figures created by class maps

function Export_Figures(M)

  % Check for existing file before exporting and ask user what to do?
  if isempty(M.figureHandle)
    short_warn('Cannot export figure, need to plot something first!');
    return;
  else
    set(0,'CurrentFigure',M.figureHandle);
  end

  % Check if folder exists
  [M.Path.folder, ~] = check_folder_existance(M.Path.folder,0);

  % first old handle is always empty due to the way we create it (end+1)
  if M.exportAllFigure
    allFigureHandles = M.oldFigureHandles(2:end);
    allFigureHandles{end+1} = M.figureHandle;
  else
    allFigureHandles = M.figureHandle;
  end
  nFigure = numel(allFigureHandles);

  fprintf('Exporting figures:')
  for iFig = 1:nFigure

    % Dont put number if we only have a single figure
    if nFigure == 1
      name_wo_ext = [M.Path.folder M.Path.name];
    else
      name_wo_ext = [M.Path.folder M.Path.name num2str(iFig)];
    end

    figure(allFigureHandles{iFig});
    fprintf('  Saving figure %i / %i...\n',iFig,nFigure);

    % Export as jpeg
    if M.exportJpg
      fprintf('   jpg...\n');
      fullPath = [name_wo_ext '.jpg'];
      [exportPath] = check_exisiting_file(fullPath,0);
      export_fig(exportPath,'-jpg','-a1',M.resolution);
    end

    % Export as pdf
    if M.exportPdf
      fprintf('   pdf...\n');
      fullPath = [M.Path.folder M.Path.name '.pdf'];
      [exportPath] = fullPath;
      export_fig(exportPath,'-pdf','-a1','-append',M.resolution);
    end

    % Export as tiff
    if M.exportTiff
      fprintf('   tiff...\n');
      fullPath = [name_wo_ext '.tiff'];
      [exportPath] = check_exisiting_file(fullPath,0);
      export_fig(exportPath,'-tiff','-a1',M.resolution);
    end

    % Export as png
    if M.exportPng
      fprintf('   png...\n');
      fullPath = [name_wo_ext '.png'];
      [exportPath] = check_exisiting_file(fullPath,0);
      export_fig(exportPath,'-png','-transparent', '-a1',M.resolution);
    end

    % Export as fig
    if M.exportFig
      fprintf('   fig...\n');
      M.Path.extention = '.fig';
      fullPath = [name_wo_ext extention];
      [exportPath] = check_exisiting_file(fullPath,0);
      savefig(exportPath);
    end

    % Export
    if ~M.exportJpg && ~M.exportPdf && ~M.exportTIFF && ~M.exportPNG && ~M.exportFIG
      fprintf('   tumble weed...nothing exported...');
    end

    % Display that procedure is over
    done();
  end

  % Open folder is we are running pc
  if (M.openExportFolder && ispc)
    winopen(M.Path.folder);
  end
end
