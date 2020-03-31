function Plot(M,varargin)
  % plot XY per default if nothing specified
  % whatPlot = 0 - plot all
  % whatPlot = 1 - plot xy map
  % whatPlot = 2 - plot xz map
  % whatPlot = 3 - plot yz map
  % whatPlot = -1 - plot map that was given as input argument

  % FIXME Use input parser to have optional name value pair input arguments
  % FIXME add optional title argument to add titles to plots automatically

  % check if input is 2d matrix, i.e. a MAP. If so, plot it
  if numel(varargin) % only true if at least one input arg
    is2dMap = (size(varargin{1},1) > 1) &&  (size(varargin{1},2));
  end

  if nargin == 1 || isempty(varargin)
    whatPlot = 1; %
  elseif nargin == 2
    if is2dMap
      whatPlot = -1; % input argument is map itself! just plot that
      plotMap = varargin{1};
    elseif isnumeric(varargin{1})
      whatPlot = varargin{1}; % input arg is what to plot
    else
      short_warn('Can''t plot whatever you are trying here!');
      return;
    end
  elseif nargin > 2
    whatPlot = varargin{1};
  end
  % M.Handle_Figures(); % make new figure or use old figure handle, see fct def for details

  %  plot with units, no idx
  if M.useUnits && ~isempty(M.x) && ~isempty(M.y)
    switch whatPlot
    case -1 % input argument is map itself! just plot that
      if M.showHisto
        subplot(1,3,[1 2]);
          imj(M.x,M.y,plotMap,'ColorMap',M.colorMap);
          xlabel('x-axis (mm)');
          ylabel('y-axis (mm)');
          title('XY-Map');
        subplot(1,3,3);
          pretty_hist(plotMap);
          title('XY-Map Histogram');
      else
        imj(M.x,M.y,plotMap,'ColorMap',M.colorMap);
        xlabel('x-axis (mm)');
        ylabel('y-axis (mm)');
        title('XY-Map');
      end
    case 1 % plot xy map
      if M.showHisto
        subplot(1,3,[1 2]);
          imj(M.x,M.y,M.xy,'ColorMap',M.colorMap);
          xlabel('x-axis (mm)');
          ylabel('y-axis (mm)');
          title('XY-Map');
        subplot(1,3,3);
          pretty_hist(M.xy);
          title('XY-Map Histogram');
      else
        imj(M.x,M.y,M.xy,'ColorMap',M.colorMap);
        xlabel('x-axis (mm)');
        ylabel('y-axis (mm)');
        title('XY-Map');
      end
    end
  %  plot with idx, no units
  else
    switch whatPlot
    case -1
      if M.showHisto
        subplot(1,3,[1 2]);
          imj(plotMap,'ColorMap',M.colorMap);
          xlabel('x-axis (idx)');
          ylabel('y-axis (idx)');
          title('XY-Map');
        subplot(1,3,3);
          pretty_hist(plotMap);
          title('XY-Map Histogram');
      else
        imj(plotMap,'ColorMap',M.colorMap);
        xlabel('x-axis (idx)');
        ylabel('y-axis (idx)');
        title('XY-Map');
      end
    case 1
      if M.showHisto
        subplot(1,3,[1 2]);
          imj(M.xy,'ColorMap',M.colorMap);
          xlabel('x-axis (idx)');
          ylabel('y-axis (idx)');
          title('XY-Map');
        subplot(1,3,3);
          pretty_hist(M.xy);
          title('XY-Map Histogram');
      else
        imj(M.xy,'ColorMap',M.colorMap);
        xlabel('x-axis (idx)');
        ylabel('y-axis (idx)');
        title('XY-Map');
      end
    end
  end

  figure(gcf);
end
