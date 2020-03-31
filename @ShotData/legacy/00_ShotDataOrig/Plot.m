% [out] = Plot(SDO,In) @ ShotData
% plot options:
% 'a_scan_overview' - gives overview using several other plots
% 'quick_a_scan_overview' - faster version of a_scan_overview
% 'max_envelope'      - plot max_of_all_shots, min_of_all_shots and
%                       abs_max_of_all_shots all in one figure
% 'max_amp_shot'      - shot with largest amplitude
% 'max_amp_spectrum'  - spectrum of max-amp shot
% 'min_amp_shot'      - shot with smallest amplitude
% 'min_amp_spectrum'   - shot with smallest amplitude
% 'abs_max_of_all_shots' - max value for each time point along all raw shots
% 'max_of_all_shots'   - max value for each time point along all shots
% 'min_of_all_shots'  - min value for each time point along all shots
% 'mean_of_all_shots' - mean value for each time point along all shots
% 'std_of_all_shots'  - standard deviaiton for each time point along all shots
% 'raw_map'           - create fake side-projection by reducing raw shots
% 'raw_map_full'      - create fake side-projection using full raw shots
% Johannes Rebling, (johannesrebling@gmail.com), 2018

function [figHandle] = Plot(SDO,plotWhat,varargin)
  if nargin < 2
    plotWhat = 'default';
  end
  % see BaseClass Plot method, this just calls it!
  % [SDO.figureHandle,plotWhat,color,colorMap] = Plot@BaseClass(SDO,plotWhat,varargin{:});

  % get x,y,z axis for plotting
  if SDO.useUnits
    x = SDO.Pos.x;
    % y = SDO.y;
    z = SDO.z;
    zLabel = 'depth (mm)';
  else
    SDO.zRange; % just makes sure some variables are calculated correctly
    x = 1:SDO.nShots;
    % y = SDO.y; % only used for volume, otherwise nY = 1;
    z = linspace(SDO.zCrop(1),SDO.zCrop(2),SDO.nSamples);
    zLabel = 'depth (idx)';
  end

  oldVerboseSetting = SDO.verboseOutput;
  oldUnitSettings = SDO.useUnits;

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % switch between all the possible plotting options
  tic; % used for all the SDO.Done();
  switch plotWhat
  case 'default'
    % close(gcf);
    SDO.Plot('quick_a_scan_overview');
    SDO.newFigPlotting = true;
    SDO.Plot('raw_map');

  case 'all' % mostly used for testing, plots everything this function can plot!
    SDO.Plot('a_scan_overview');
    SDO.Plot('quick_a_scan_overview');
    SDO.Plot('max_envelope');
    SDO.Plot('max_amp_shot');
    SDO.Plot('max_amp_spectrum');
    SDO.Plot('min_amp_shot');
    SDO.Plot('min_amp_spectrum');
    SDO.Plot('abs_max_of_all_shots');
    SDO.Plot('max_of_all_shots');
    SDO.Plot('min_of_all_shots');
    SDO.Plot('mean_of_all_shots');
    SDO.Plot('std_of_all_shots');
    SDO.Plot('raw_map');

  case 'a_scan_overview' % get a-scan overview
    SDO.VPrintF('Plotting A-Scan overview...');
    SDO.newFigPlotting = false;
    SDO.verboseOutput = false;
    subplot(2,2,1);
      SDO.Plot('max_amp_shot'); % shot with largest amplitude
    subplot(2,2,2);
      SDO.Plot('min_amp_spectrum'); % mean value for each time point along all raw shots
      hold on;
      SDO.Plot('max_amp_spectrum'); % mean value for each time point along all raw shots
    subplot(2,2,3);
      SDO.Plot('max_envelope'); % min, max and absmax plot
    subplot(2,2,4);
      SDO.Plot('std_of_all_shots'); % max value for each time point along all shots
    sub_plot_title('A-Scan Overview');
    SDO.Done();

  case 'quick_a_scan_overview' % get a-scan overview %%%%%%%%%%%%%%%%%%%%%%%%%%%
    SDO.VPrintF('Plotting quick A-Scan overview...');
    SDO.verboseOutput = false;
    SDO.newFigPlotting = false;
    subplot(2,2,1);
      SDO.Plot('max_amp_shot'); % shot with largest amplitude
    subplot(2,2,2);
      SDO.Plot('min_amp_spectrum'); % mean value for each time point along all raw shots
      hold on;
      SDO.Plot('max_amp_spectrum'); % mean value for each time point along all raw shots
    subplot(2,2,3);
      SDO.Plot('max_envelope'); % max value for each time point along all raw shots
    subplot(2,2,4);
      SDO.Plot('mean_of_all_shots'); % shot with largest amplitude
    sub_plot_title('Quick A-Scan Overview');
    SDO.Done();

  case 'max_envelope' % plot max_of_all_shots, min_of_all_shots and abs_max_of_all_shots
    SDO.VPrintF('Plotting quick A-Scan overview...');
    SDO.verboseOutput = false;
    SDO.newFigPlotting = false;
    SDO.Plot('max_of_all_shots');
    hold on;
    SDO.Plot('min_of_all_shots');
    SDO.Plot('abs_max_of_all_shots');
    title('min/max/abs(max) of all a-scans');
    SDO.Done();

  case 'max_amp_shot' % shot with largest amplitude
    SDO.VPrintF('Plotting shot with max amplitude...');
    plot(z,SDO.maxAmpShot);
    axis tight;
    xlabel(zLabel);
    ylabel('shot value (mV or counts)');
    title(sprintf('abs. max. amplitude shot (idx=%i)',SDO.maxAmpIdx));
    SDO.Done();

  case 'max_amp_spectrum' % spectrum of max-amp shot
    SDO.VPrintF('Plotting spectrum of max. amp. shot...');
    plot(SDO.freq*1e-6,SDO.maxAmpSpec);
    axis tight;
    xlabel('frequency (MHz)');
    ylabel('spectral density (a.u.)');
    title('abs. max. amplitude spectrum');
    SDO.Done();

  case 'min_amp_shot' % shot with smallest amplitude
    SDO.VPrintF('Plotting shot with min. amplitude...');
    plot(z,SDO.minAmpShot);
    axis tight;
    xlabel(zLabel);
    ylabel('shot value (mV or counts)');
    title('shot with min. amplitude');
    SDO.Done();

  case 'min_amp_spectrum' % spectrum of min-amp shot
    SDO.VPrintF('Plotting spectrum of min. amp. shot...');
    plot(SDO.freq*1e-6,SDO.minAmpSpec);
    axis tight;
    xlabel('frequency (MHz)');
    ylabel('spectral density (a.u.)');
    title('abs. max. amplitude spectrum');
    SDO.Done();

  case 'abs_max_of_all_shots' % max value for each time point along all raw shots
    SDO.VPrintF('Plotting abs. max. of all shots...');
    plot(z,SDO.absMaxShot);
    axis tight;
    xlabel(zLabel);
    ylabel('max value (mV or counts)');
    title('abs. max. of all a-scans');
    SDO.Done();

  case 'max_of_all_shots' % max value for each time point along all shots
    SDO.VPrintF('Plotting max. of all shots...');
    plot(z,SDO.maxShot);
    axis tight;
    xlabel(zLabel);
    ylabel('max value (mV or counts)');
    title('max. of all a-scans');
    SDO.Done();

  case 'min_of_all_shots' % min value for each time point along all shots
    SDO.VPrintF('Plotting max of all shots...');
    plot(z,SDO.minShot);
    axis tight;
    xlabel(zLabel);
    ylabel('min value (mV or counts)');
    title('min. of all a-scans');
    SDO.Done();

  case 'mean_of_all_shots' % mean value for each time point along all shots
    SDO.VPrintF('Plotting mean of all shots...');
    plot(z,SDO.meanShot);
    axis tight;
    xlabel(zLabel);
    ylabel('mean value (mV or counts)');
    title('mean A-Scan');
    SDO.Done();

  case 'std_of_all_shots'  % standard deviaiton for each time point along all shots
    SDO.VPrintF('Plotting standard deviation of all shots...');
    plot(z,SDO.stdShot);
    axis tight;
    xlabel(zLabel);
    ylabel('standard deviation');
    title('a-scan standard deviation');
    SDO.Done();

  case 'raw_map' % create fake side-projection by reducing raw map shots
    tic();
    SDO.VPrintF('Plotting raw maps...');
    % raw data typically huge, lets look at only the max/mean over a number
    % of shots to create a matrix that makes sense to display with a size of
    % nShots x 1000
    % size(SDO.raw) = 601 x 46798
    % get smaller raw for plotting, also makes this step much faster
    % and less memory intensive...
    % every 2nd sample, every 7th shot = 8 times less data
    downSampleFactors = [2 10];
    nPixels = SDO.Pos.ntargetBscans; % each y-line is approx. a b-scan
    if ~nPixels
        nPixels = 100; % use as default in nBscans is not known...
    end

    if size(SDO.raw,2) > nPixels
      tempRaw = SDO.Get_Down_Sampled_Raw(downSampleFactors);
      tempRaw = split_2D_to_3D_matrix(tempRaw, nPixels);
      overViewMap = squeeze(nanmax(tempRaw))';
      xPlot = x./1000;
    else
      overViewMap = SDO.raw();
      xPlot = x;
    end
    subplot(1,4,[1 3])
      if SDO.dt
        zDepth = flip(-(0:numel(z)-1)*SDO.dt*SDO.SOS_WATER*1e3);
        image_yy(xPlot,z,overViewMap,zDepth,'rel. depth (mm)');
      else
        imagesc(xPlot,z,overViewMap);
      end
      colormap(colorMap);
      xlabel('shots (idx/1000)');
      ylabel(zLabel);
      title('Raw Overview');
      % make horizontal grind lines to easier assess depth limits
      grid on;
      grid minor;
      ax = gca;
      ax.GridAlpha = 0.25;
      ax.GridColor = [1 1 1];
      ax.MinorGridAlpha = 0.125;
      ax.MinorGridColor = [1 1 1];
      ax.XMinorGrid = 'off';

    depthSignalPlot = std(single(overViewMap),[],2);
    subplot(1,4,4)
      zIdx = linspace(min(z),max(z),numel(depthSignalPlot));
      plot(depthSignalPlot,zIdx);
      axis tight;
      axis ij; % flip plot along horizontal axis to match image
      title('depth signal (std)')
      grid on;
      grid minor;
    SDO.Done();

  case 'filtered_raw_map' % create fake side-projection by reducing raw map shots
    tic();
    SDO.VPrintF('Plotting raw maps...');
    % raw data typically huge, lets look at only the max/mean over a number
    % of shots to create a matrix that makes sense to display with a size of
    % nShots x 1000
    % size(SDO.raw) = 601 x 46798
    % get smaller raw for plotting, also makes this step much faster
    % and less memory intensive...
    % every 2nd sample, every 7th shot = 8 times less data
    downSampleFactors = [2 10];
    nPixels = SDO.Pos.ntargetBscans; % each y-line is approx. a b-scan
    tempRaw = SDO.Get_Down_Sampled_Raw(downSampleFactors);
    if any(SDO.Filter.freq)
     SDO.Filter.Define();
     tempRaw = SDO.Filter.Apply(tempRaw);
    end
    depthSignalPlot = std(single(tempRaw),[],2);
    tempRaw = split_2D_to_3D_matrix(tempRaw, nPixels);
    meanby = squeeze(nanmax(tempRaw))';

    subplot(1,4,[1 3])
      kShots = 1:SDO.nShots./1000; % k Shots
      depthIdx = linspace(SDO.zCrop(1),SDO.zCrop(2),SDO.nSamples);
      if SDO.dt % we know the sample rate, so turn idx into depth
        image_yy(kShots,depthIdx,meanby,SDO.depth,'rel. depth (mm)');
        ylabel('depth (mm)');
      else
        imagesc(kShots,z,meanby);
      end
      colormap(colorMap);
      xlabel('shots (idx/1000)');
      ylabel(zLabel);
      title('Raw Overview');
      % make horizontal grind lines to easier assess depth limits
      grid on;
      grid minor;
      ax = gca;
      ax.GridAlpha = 0.25;
      ax.GridColor = [1 1 1];
      ax.MinorGridAlpha = 0.125;
      ax.MinorGridColor = [1 1 1];
      ax.XMinorGrid = 'off';

    subplot(1,4,4)
      zIdx = linspace(min(z),max(z),numel(depthSignalPlot));
      plot(depthSignalPlot,zIdx);
      axis tight;
      axis ij; % flip plot along horizontal axis to match image
      title('depth signal (std)')
      grid on;
      grid minor;
    SDO.Done();

  otherwise
    SDO.PrintF('Unknown plot option ''%s''!\n',plotWhat);
  end

  if SDO.noColorBar
    colorbar off;
  else
    colorbar;
  end

  if SDO.noAxis
    axis off;
  end

  if SDO.drawNow
    drawnow limitrate; % show latest plot, slow when in for loop!!!
  end

  SDO.verboseOutput = oldVerboseSetting;
  SDO.useUnits = oldUnitSettings;
  figureHandle = SDO.figureHandle;

end
