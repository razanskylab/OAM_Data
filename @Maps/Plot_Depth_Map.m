function [minAmp,depthRange] = Plot_Depth_Map(M,plotStyle,minAmp,depthRange)
  % plot overlayed depth map (doPlotOverview=1, default) or raw depth map
  if isempty(M.depthInfo)
    short_warn('Need to define Maps.depthInfo before useing Maps.Plot_Depth_Map!');
    return;
  else
    dMap = M.depthInfo;
  end

  if nargin == 1
    plotStyle = 'raw';
    minAmp = [];
    depthRange = [];
  elseif nargin == 2
    minAmp = [];
    depthRange = [];
  elseif nargin == 3
    depthRange = [];
  end

  % M.Handle_Figures(); % make new figure or use old figure handle, see fct def for details

  switch plotStyle
    case 'default'
      mip = M.xy;
      mip(isnan(mip)) = 0; % replaces all potential NANs
      mip = normalize(mip);
      normalMip = mip;
      mip = adapthisteq(mip);
      mip = normalise(mip);

      depthRangeMap = dMap;
      depthRangeMap(normalMip < 0.1) = NaN;
      lowLim = min(depthRangeMap(:));
      upLim = max(depthRangeMap(:));
      dMap(dMap<lowLim) = lowLim;
      dMap(dMap>upLim) = upLim;

      % create labels
      nDepthLabels = 10;
      indexRange = round(linspace(lowLim,upLim,nDepthLabels));
      currentTickLims = [0 1];
      tickLocations = linspace(min(currentTickLims),max(currentTickLims),nDepthLabels);
      tickValues = linspace(lowLim,upLim,nDepthLabels);
      for iLabel = 1:nDepthLabels
        zLabels{iLabel} = sprintf('%2.2f',tickValues(iLabel));
      end
      zLabels{1} = 'closer';
      zLabels{end} = 'deeper';

      cBar = M.Overlay_Mask(dMap,mip,2,mip); % overlays Oa.xy over default background, i.e. Oa.filt

      cBar.Ticks = tickLocations;
      cBar.TickLabels = zLabels;


    case 'raw' % plot as is, no further processing
      % plot raw depth map (not overlayed) to get correct color map
      imj(M.x,M.y,dMap,'ColorMap',M.depthColorMap);
      colorbar;
      colormap(gca,M.depthColorMap);
      c1 = colorbar();
      % rename ticks to have units and they look nice
      maxTick = max(dMap(:));
      minTick = min(dMap(:));
      allTicks = minTick:M.depthStepSize:maxTick; % make linear spaced ticks
      % max tick might not be in linear space range, so add it if needed
      if ~(allTicks(end) == maxTick)
        allTicks(end+1) = maxTick;
      end
      c1.Ticks = allTicks;
      c1.TickLabels = num2str(allTicks','%04.2f mm');
      copyTicks = c1.Ticks;
      copyTickLabes = c1.TickLabels;

      % now we delete to other map and just use those tick labels for the overlayed iamges
      imj(M.x,M.y,dMap,'ColorMap',M.depthColorMap);

      % title(fileName,'Interpreter','none');
      title('Depth Map (OA)');
      c2 = colorbar();
      c2.Ticks = normalize(copyTicks);
      c2.TickLabels = copyTickLabes;
      title('Depth Map (OA)');
      xlabel('x-axis (mm)');
      ylabel('y-axis (mm)');

    case {'cropped','diff'} % remove outliers but leave global trend
      % M.maskFrontCMap = Colors.greenOrangeBlueFUI; % custom made color map, see Colors class
      M.maskFrontCMap = jet(256); % custom made color map, see Colors class
      M.maskBackCMap = 'gray';
      map = M.xy;
      map(isnan(map)) = 0; % replaces all potential NANs
      map = normalize(map);

      dMap = dMap - min(dMap(:)); % shift so depth map starts at 0

      % ignore depth infos for locations where we have none or very weak OA signal
      % as it's hard to define what 'weak' is, we ask the user to help us
      if isempty(minAmp)
        figure();
        [counts,x] = hist(map(:),100);
        stem(x,counts); xlabel('map amplitudes');
        minAmp = input('Enter min map amplitude [low]: ');
        close(gcf);
      end
      dMap(map < minAmp) = NaN;
      dMap = fillmissing(dMap,'linear');

      if strcmp(plotStyle,'diff')
        % get smooth depth map and plot local differences to this global map
        dMapSmooth = imgaussfilt(dMap,5);
        dMap = dMap - dMapSmooth;
      else
        dMap = dMap - min(dMap(:)); % shift so depth map starts at 0
      end

      % then remove clear outliers...also hard, so ask for help again!
      if isempty(depthRange)
        figure();
        [counts,x] = hist(dMap(:),100);
        stem(x,counts); xlabel('depths (idx or mm)');
        depthRange = input('Enter [min max] depth: ');
        close(gcf);
      end
      dMap(dMap < depthRange(1)) = depthRange(1);
      dMap(dMap > depthRange(2)) = depthRange(2);

      if ~strcmp(plotStyle,'diff')
        dMap = dMap - min(dMap(:)); % shift so depth map starts at 0
      end

      % Overlay_Mask(M,front,back,transparency,alphaMask)
      cBar = M.Overlay_Mask(dMap,map,1.5,map); % overlays Oa.xy over default background, i.e. Oa.filt
      cBar.Label.String = 'relative depth (mm)';

    case 'diff' % remove outliers and remove global trend

    otherwise
      M.Verbose_Warn('Unknown depth map plot option, Jerry!');
  end

end
