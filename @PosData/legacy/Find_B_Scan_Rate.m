% [bScanRate] = Find_B_Scan_Rate(Pos,In) @ Pos
% Johannes Rebling, (johannesrebling@gmail.com), 2018


function [bScanRate] = Find_B_Scan_Rate(Pos)
  % two ways to get rate of b-scan (half the movement period)
  % fast and easy - get zero crossings and calc rate based on that
  % accurate but slow - fit sinusoidal function to smoothed position data...
  %
  tic;
  Pos.VPrintF('Finding B-scan rate...');

  % 1st Version ----------------------------------------------------------------
  Pos.VPrintF('using 0-cross...');
  x = Pos.xSSmooth;
  x = x - mean(x); % make zero centerd
  nZeroCrossings = sum(abs(diff(x>0)));
  bScanRate = nZeroCrossings/length(x);
  bScanRate1 = bScanRate.*Pos.prf;
  Pos.nXSBscans(1) = nZeroCrossings;

  % 2nd Version - FFT of smoothed data... --------------------------------------
  Pos.VPrintF('using fft...');
  smoothWidth = Pos.bScanPeriod*Pos.prf;
  x = movmean(Pos.xS,smoothWidth);
  x = x - mean(x); % center at zero
  [f, specAmp] = fast_fft_pro(Pos.dt,x,0,0,0,[0 1]); % no plotting, smoothing etc
  [~,maxIdx] = max(specAmp);
  bScanRate2 = f(maxIdx)*2; % factor two because we want b-scan rate

  % 3rd Version with fitting of sinusoid to smoothed data
  % smooth over a full period to turn trapezoid into sinusoid
  % this might change the xMin/xMax but we only care about period here
  % NOTE no need to do this?

  Pos.Done();
  % bScanRate = mean([bScanRate1 bScanRate2]);
  bScanRate = mean([bScanRate1 bScanRate2]); % FFT should give more stable results
  fprintf('   Found a B-scan rate of %2.2f Hz (0-cross = %2.2f Hz).\n',...
    bScanRate,bScanRate1);

  rateDiff = abs(bScanRate1-bScanRate2);
  if rateDiff > Pos.ALLOWED_RATE_DIFF
    short_warn('Large difference in found B-scan rates! Check this!');
  end
end
