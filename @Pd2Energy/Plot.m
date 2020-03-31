% Plot(Pd2Energy,plotOption)
% unified plotting function, with the following plotting options
% plotOption:
% 'Single Meas' - overview plot for single pd measurement (recursive because it's cool)
% 'Overview' - overview plot
% 'Corr_Vs_Time' - plot correlation of pd vs pm over time using smaller windows
% 'Pd_Signals_Long' - plot min/max/mean pd signals, noise and analysis window
% 'Pd_Signals_Long' - plot min/max/mean pd signals cropped to analysis window
% 'Energy_Trend_Full' - shows full time line of pd and pm signals
% 'Energy_Trend_Start_Stop' - shows start/stop of pd and pm signals
% 'Correlation' - correlation of pd and pm signals and fit results
% 'Error_Info' - error vs shots in nJ together with info on mean error
%
% FIXME: https://gitlab.lrz.de/razan-sky-lab/HFOAM/issues/62
%
% Johannes Rebling, (johannesrebling@gmail.com), 2018

function Plot(PDE,plotOption,varargin)
  % grand unified plot option, mighht be better than twenty seperate files?
  switch PDE.mode
  end

  if nargin == 3
    color = varargin{1};
  elseif nargin == 2
    color = [];
  else
    plotOption = 'Overview'; % should work always?
    color = [];
  end

  % get pd and pm as it's used everywhere....
  pd = PDE.pd; % [a.u!]
  pm = PDE.pm.*1e6;

  pmSort = PDE.pmSort.*1e6;
  pdSort = PDE.pdSort;
  pmFit = PDE.pmFit.*1e6;
  pmFitUnsort = PDE.pmFitUnsort.*1e6;

  pdMax = PDE.pdMax;
  pdMin = PDE.pdMin;
  pdMean = PDE.pdMean;

  switch plotOption
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  case 'Single Meas' % this is where we get sneaky and use recursion...
    % generate overview plot for current PDE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    figure();
    % correlation is poor, plot an overview
    subplot(5,4,1)
      PDE.Plot('Pd_Signals_Long');
    subplot(5,4,2)
      PDE.Plot('Pd_Signals_Short');
    subplot(5,4,[5 6])
      PDE.Plot('Energy_Trend_Full');
    subplot(5,4,[9 10])
      PDE.Plot('Energy_Trend_Start_Stop');
    subplot(5,4,[13 14]);
      PDE.Plot('Corr_Vs_Time');

    subplot(5,4,17);
      PDE.Plot('Pd_Histo');

    subplot(5,4,18);
      PDE.Plot('Pm_Histo');

    subplot(3,2,2);
      PDE.Plot('Correlation');
    subplot(3,2,4);
      PDE.Plot('Error_Info');
    subplot(3,2,6);
      PDE.Plot('Error_Image');
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  case 'Overview' % this is where we get sneaky and use recursion...
    % generate overview plot for current PDE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    figure();
    subplot(3,2,3)
      PDE.Plot('Energy_Trend_Full');
    subplot(3,2,5);
      PDE.Plot('Corr_Vs_Time');

    subplot(3,2,[1 2]);
      PDE.Plot('Correlation');
    subplot(3,2,4);
      PDE.Plot('Error_Info');
    subplot(3,2,6);
      PDE.Plot('Error_Image');
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  case 'Pd_Histo' %plot correlation of pd vs pm over time using smaller windows
    pretty_hist(pd);
    xlabel('PD signal [a.u.]');
    title('PD signal distribution');
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  case 'Pm_Histo' %plot correlation of pd vs pm over time using smaller windows
    pretty_hist(pm);
    xlabel('PM signal [uJ]');
    title('PM signal distribution');
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  case 'Corr_Vs_Time' %plot correlation of pd vs pm over time using smaller windows
    corrWindowPer = 1;
    corrWindow = round(corrWindowPer/100*length(pd));
    nWindows = length(pd)./corrWindow;
    corrs = zeros(nWindows,1);
    % FIXME rewrite as vector code?
    for iWin = 1:nWindows
      startIdx = corrWindow+iWin;
      endIdx = 2*corrWindow+iWin-1;
      pdTemp = pd(startIdx:endIdx);
      pmTemp = pm(startIdx:endIdx);
      corrs(iWin) = corr(pdTemp,pmTemp);
    end
    x = (1:nWindows)*corrWindow;
    plot(x,corrs,'LineWidth',2);
    ylabel('Linear Correlation');
    titleStr = sprintf('Correlation Over Time (%.0f%% window)',corrWindowPer);
    title(titleStr);
    axis tight;
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  case 'Pd_Signals_Long' % plot min/max/mean pd signals, noise and analysis window
    hold on
    plot(pdMean);
    plot(pdMax);
    plot(pdMin);
    l = legend({'Mean','Max','Min'});
    l.FontSize = PDE.LEGEND_FONT_SIZE;
    title('PD Signal Shape');
    axis tight;
    xlabel('Samples');
    ylabel('PD Signal Amplitude (V)');

    ax = gca;
    y = [ax.YLim(1) ax.YLim(2)];
    x1 = [min(PDE.noiseWindow) min(PDE.noiseWindow)];
    plot(x1,y,'--','Color',Colors.DarkRed);
    x1 = [min(PDE.signalWindow) min(PDE.signalWindow)];
    plot(x1,y,'-.','Color',Colors.DarkGreen);
    x2 = [max(PDE.noiseWindow) max(PDE.noiseWindow)];
    plot(x2,y,'--','Color',Colors.DarkRed);
    x2 = [max(PDE.signalWindow) max(PDE.signalWindow)];
    plot(x2,y,'-.','Color',Colors.DarkGreen);

    l = legend({'Mean','Max','Min','Noise','Analysis'});
    l.FontSize = PDE.LEGEND_FONT_SIZE;%%
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  case 'Pd_Signals_Short' %  plot min/max/mean pd signals cropped to analysis window
    hold on
    plot(pdMean(PDE.signalWindow));
    plot(pdMax(PDE.signalWindow));
    plot(pdMin(PDE.signalWindow));
    axis tight;
    l = legend({'Mean','Max','Min'});
    l.FontSize = PDE.LEGEND_FONT_SIZE;
    title('PD Analysis Window');
    xlabel('Samples');
    ylabel('PD Signal Amplitude (V)');
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  case 'Energy_Trend_Full' % shows full time line of pd and pm signals
    meanPD = mean(pd);
    meanPM = mean(pm);
    pd = pd*(meanPM/meanPD);

    plot(pd);
    hold on
    plot(pm,'--');
    title('PD vs PM - Complete');
    axis tight;
    ylabel('Energy (\muJ)');
    l = legend({'Photodiode','Power Meter'});
    l.FontSize = PDE.LEGEND_FONT_SIZE;
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  case 'Energy_Trend_Start_Stop' % shows start/stop of pd and pm signals
    pdMean = mean(pd);
    pmMean = mean(pm);
    pd = pd*(pmMean/pdMean);

    checkLenght = 50;
    pdPlot = [pd(1:checkLenght)' pd((end-checkLenght):end)'];
    pmPlot = [pm(1:checkLenght)' pm((end-checkLenght):end)'];
    plot(pdPlot);
    hold on
    plot(pmPlot);
    title('PD vs PM - Start and End');
    axis tight;
    ylabel('Energy (\muJ)');

    ax = gca;
    y = [ax.YLim(1) ax.YLim(2)];
    x = [checkLenght checkLenght];
    plot(x,y,'--k');
    l = legend({'Photodiode','Power Meter'});
    l.FontSize = PDE.LEGEND_FONT_SIZE;
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  case 'Correlation'
    % takes sortet power meter and photodiode data, correlation and
    % the ployfit results and plots it all togheter
    pmMean = mean(pmSort);
    pdMean = mean(pdSort);
    pdMatched = pdSort*(pmMean/pdMean);

    meanBasedError = mean(abs(pdMatched-pmSort))./pmMean*100;

    pmFitError(1,:) = pmFit + PDE.Poly.fitDelta*1e6;
    pmFitError(2,:) = pmFit - PDE.Poly.fitDelta*1e6;

    legendEntry{1} = 'Raw Data';
    p = scatter(pmSort,pdSort,'.');
    p.MarkerFaceColor = Colors.DarkGray;
    p.MarkerEdgeColor = Colors.DarkGray;
    p.MarkerFaceAlpha = 0.1;
    p.MarkerEdgeAlpha = 0.1;
    hold on

    legendEntry{2} = 'Polyfit';
    p1 = plot(pmFit,pdSort,'.');
    if ~isempty(color)
      p1.Color = color;
    else
      p1.Color = Colors.DarkGreen;
    end

    %l = legend(legendEntry,'Location','best');
    %l.FontSize = PDE.LEGEND_FONT_SIZE;
    titleStr = sprintf(['PD vs PM correlation\n Linear: %.2f | '...
    'Spearman: %.2f | Error ~%.2f%%'],PDE.corValues,meanBasedError);
    axis tight;
    xlabel('Power Meter Energies (\muJ)');
    ylabel('Photodiode Energies (a.u.)');

    title(titleStr);
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  case 'Error_Info' %  error vs shots in nJ together with info on mean error
    fitErrorAbs = mean(abs(pmFit-pmSort))*1e3;
    fitErrorPer = mean(abs(pmFit-pmSort))./mean(pmSort)*100;
    nShots = length(pd);

    meanPD = mean(pd);
    meanPM = mean(pm);
    pd = pd*(meanPM/meanPD);
    linError = abs(pd-pm)*1e3;

    plot(linError);
    hold on
    axis tight
    y = [fitErrorAbs fitErrorAbs];
    x = [1 nShots];
    plot(x,y,'r--','LineWidth',2)
    hold off
    title(sprintf('Mean Abs Error = %.1f nJ (%2.2f%%)',fitErrorAbs,fitErrorPer));
    xlabel('Shots -->');
    ylabel('Abs. Error (nJ)');
    l = legend({'Error','Average PD Cal Error'});
    l.FontSize = PDE.LEGEND_FONT_SIZE;
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  case 'Error_Image' % absolute error of pm vs pmFit
    absError = abs(pmFit-pm).*100;
    errorMean = mean(absError(:));
    errorStd = std(absError(:));
    % move outliers in a little to compress range for plotting
    absError(absError>errorMean+3*errorStd) = errorMean+3*errorStd;

    % for a square image, we would use this widht
    width = ceil(sqrt(length(absError)));
    % but we want it to be wider and not not as high, so we use this widh
    width = 2*width;

    absErrorIm = vec2mat(absError,width);

    imagesc(absErrorIm);
    title('Absolute Error (%)');
    colorbar;
    colormap(Colors.redOrangeGreenFUI);
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  case 'Error_Map' % same as error image but remapped to actual coordinates
    % requires interpolation, so we expect some more input here
    % we'll need to figure out
    absError = abs(pm-pmFit).*100;
    errorMean = mean(absError(:));
    errorStd = std(absError(:));
    % move outliers in a little to compress range for plotting
    absError(absErrorIm>errorMean+3*errorStd) = errorMean+3*errorStd;

    % for a square image, we would use this widht
    width = ceil(sqrt(length(absErrorIm)));
    % but we want it to be wider and not not as high, so we use this widh
    width = 2*width;

    absErrorIm = vec2mat(absError,width);

    imagesc(absErrorIm); axis image;
    title('Absolute Error (%)');
    colorbar;
    colormap(Colors.redOrangeGreenFUI);

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  otherwise
    warning('[PDE] Unknown plot option!');
  end

end
