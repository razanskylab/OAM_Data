% [figHandle] = Plot(Pos,plotWhat,varargin)
% Pos.Plot('overview');
% Pos.Plot('sample_space');
% Johannes Rebling, (johannesrebling@gmail.com), 2018

function [figHandle] = Plot(Pos,plotWhat,varargin)
  if nargin < 2
    plotWhat = 'overview';
  end

  % see BaseClass Plot method, this just calls it!
  [figHandle,plotWhat,color,colorMap] = Plot@BaseClass(Pos,plotWhat,varargin{:});

  if isempty(figHandle)
    figHandle = figure();
  end
  switch plotWhat
  case 'all' %
    Pos.Plot('overview');
    Pos.Plot('sample_space');
  case 'overview' % get a-scan overview
    endPeriod = find(Pos.tS > Pos.bScanPeriod*2*5,1);
    plotRange = 1:endPeriod; % show 5 periods
    plotRange = plotRange + round(Pos.nShots./2); % plot somewhere in the middle
    if plotRange(end) > Pos.nShots
      plotRange = 1:(round(Pos.prf*Pos.bScanRate*2*5)); % show 5 periods
    end
    subplot(2,2,1)
      plot(Pos.tS(plotRange),Pos.xS(plotRange));
      title('Raw and Filtered Pos.');
      legend('raw pos.','smoothed pos');
      xlabel('time (s)');
      ylabel('position (mm)');
    subplot(2,2,2)
      plot(Pos.tS(plotRange),abs(Pos.xVel(plotRange)));
      axis tight;
      title('Velocity Profile.');
      % legend('raw pos.','smoothed pos');
      xlabel('time (s)');
      ylabel('abs. velocity (mm/s)');
    subplot(2,2,3)
      pretty_hist(abs(Pos.xS));
      axis tight;
      xlabel('position (mm)');
      title('Position Distribution');
    subplot(2,2,4)
      pretty_hist(abs(Pos.xVel));
      axis tight;
      xlabel('velocity (mm/s)');
      title('Velocity Distribution');
    figure(figHandle); % make current figure the figure...

  case 'sample_space' % get a-scan overview
    regularX = Pos.xReg; % zig-zag (not saw tooth...)
    regularY = Pos.yReg; % staircase
    realXPos = Pos.xS;
    realYPos = Pos.yS;

    subplot(1,2,1)
      size = 7;
      alpha = 0.5;
        scatter(realXPos,realYPos,size,...
        'MarkerEdgeColor','none',...
        'MarkerFaceAlpha',alpha,...
        'MarkerFaceColor',Colors.DarkOrange);
      hold on;
      scatter(regularX,regularY,4,...
      'MarkerEdgeColor','none',...
      'MarkerFaceAlpha',0.5,...
      'MarkerFaceColor',Colors.DarkGreen);
      axis tight;
      axis image;
      xlabel('x-pos (mm)');
      ylabel('y-pos (mm)');
      title('x-y sample space')

    subplot(2,2,2)
      plot(Pos.xS-mean(Pos.xS));
      hold on;
      plot(Pos.yS-mean(Pos.yS));

      axis tight;
      xlabel('idx');
      ylabel('abs pos (mm)');
      legend('x-pos','y-pos');
      title('scattered sampled points');

    subplot(2,2,4)
      plot(Pos.xReg-mean(Pos.xReg));
      hold on;
      plot(Pos.yReg-mean(Pos.yReg));

      axis tight;
      xlabel('idx');
      ylabel('abs pos (mm)');
      legend('x-pos','y-pos');
      title('regular-spaced output sampled points');
  otherwise
  end
  drawnow limitrate;
end
