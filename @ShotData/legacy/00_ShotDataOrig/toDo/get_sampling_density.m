function [ExpData] = get_sampling_density(ExpData,Conf)
  % calculate the number of sample points per interolated grid point
  hor_div;
  disp('Calculating sampling density...')

  % if downsample data point density notify user
  if mod(Conf.Plot.mapDownsampling,1)
    color_message('Changed sampling map downsampling to an interger value.\n')
    fprintf('Conf.Plot.mapDownsampling was %2.1f now is %i.\n',...
      Conf.Plot.mapDownsampling,round(Conf.Plot.mapDownsampling));
    Conf.Plot.mapDownsampling = round(Conf.Plot.mapDownsampling);
  end

  fprintf('Using a %ix downsampled grid for the sampling density map.\n',...
    Conf.Plot.mapDownsampling);

  % get local copies of variables to have easier to read code...
  realX = ExpData.RealXPosVec;
  realY = ExpData.RealYPosVec;
  X = ExpData.XPosVec;
  Y = ExpData.YPosVec;

  % define bins surronding the ideal shot positions (defined in
  % XPosVec & YPosVec)
  % e.g.: for x axis from 1 to 10 with stepsize = 1 the bins would be
  % 0.5 1.5 2.5 ... 10.5
  xStepSize = mean(diff(X));
  minXBin = min(X)-xStepSize/2;
  maxXBin = max(X)+xStepSize/2;
  xStepSize = xStepSize*Conf.Plot.mapDownsampling;
  xBins = minXBin:xStepSize:maxXBin;
  nXBins = length(xBins);

  yStepSize = mean(diff(Y));
  minYBin = min(Y)-yStepSize/2;
  maxYBin = max(Y)+yStepSize/2;
  yStepSize = yStepSize*Conf.Plot.mapDownsampling;
  yBins = minYBin:yStepSize:maxYBin;
  nYBins = length(yBins);

  % allocate memory for samplingDensity map
  samplingDensity = zeros(nXBins-1,nYBins-1);

  % ----------------------------------------------------------------------------
  fprintf('Finding shots per sample area...')
  % find density on a per-bin basis, couldn't come up with a faster
  % way other then this...
  if Conf.parallelProcessing
    nWorkers = Inf; % use as many workers as available
  else
    nWorkers = 0; % don't run in parallel
  end
  parfor (xBin = 1:(nXBins-1),nWorkers)
    for yBin = 1:(nYBins-1)
      % find indicies of x values in range of current bin
      inXRange = (xBins(xBin) < realX) & (realX <= xBins(xBin+1));
      % find indicies of  y values in range of current bin
      inYRange = (yBins(yBin) < realY) & (realY <= yBins(yBin+1));
      % find points where both are within the current bin
      inBothRanges = inXRange & inYRange;
      samplingDensity(xBin,yBin) = nnz(inBothRanges); % get number of that...
    end
  end
  % remove outer Conf.Plot.mapBorderRemoval pixels
  nPx = Conf.Plot.mapBorderRemoval;
  [xSize,ySize] = size(samplingDensity);
  % check if resulting map size is bigger than zero
  xSize = xSize - 2*nPx;
  ySize = ySize - 2*nPx;
  if (xSize > 1) && (ySize > 1)
    samplingDensity = samplingDensity((1+nPx:end-nPx),(1+nPx:end-nPx));
  else
      % don't remove border...
  end
  % get average sampling density per area insted of total count
  samplingDensity = samplingDensity/(Conf.Plot.mapDownsampling^2);
  meanSamplingDensity = mean(samplingDensity(:));
  maxSamplingDensity = round(max(samplingDensity(:)));
  minSamplingDensity = round(min(samplingDensity(:)));

  fprintf('done!\n');

  fprintf('Mean sampling density: %2.1f (Min: %i |Max: %i). \n', ...
    meanSamplingDensity,minSamplingDensity,maxSamplingDensity);
  lessThanOneSample = sum(sum(samplingDensity<1));
  percentUnsampled = 100*lessThanOneSample/numel(samplingDensity);
  %
  % fprintf(['%.3g%% (n=%i) of the interpolated positions have less \n' ...
  %   'then an averge of one sample point per interpolated grid. \n'], ...
  %   percentUnsampled,lessThanOneSample);

  ExpData.SamplingDensity = samplingDensity;
  ExpData.XBins = xBins;
  ExpData.YBins = yBins;

end
