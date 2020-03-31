function [range,keepIdx,startIdx,endIdx] = Find_Scan_Oscillation_Range(Pos)
  % returns the range betweeen which the x-stage is actually oscilating
  % back and forth during a scan/calibration, i.e. removes the start and
  % end bits where the stage is not actually moving

  % this could all be done with the get functions for the properties
  % such as xSSmooth and vel, but then we would calculate a lot of useless
  % stuff so instead we just just the first and last few oscilations...
  tic;
  Pos.VPrintF('Finding range of stage oscilations...');
  if Pos.ntargetBscans < Pos.N_OSC_PERIODS*2
    nSamples = round(Pos.bScanPeriod*Pos.prf*Pos.ntargetBscans*0.4);
  else
    nSamples = round(Pos.bScanPeriod*Pos.prf*Pos.N_OSC_PERIODS*2);
  end
  
  smoothWidth = Pos.bScanPeriod/4*Pos.prf;

  oscStart = Pos.xS(1:nSamples);
  oscSmooth = movmean(oscStart,smoothWidth);
  velSmooth = abs(gradient(oscSmooth,Pos.dt)); % get velSmoothocity profile
  % sometimes there is vel. spike at start or end, get rid of it
  startOffset = 100;
  velSmooth = velSmooth(startOffset:end);
  speedLim = max(velSmooth)*(Pos.SPEED_LIM_PER/100);
  startIdx = find(velSmooth > speedLim,1,'first') + startOffset; % find index of last "zero"

  if Pos.verbosePlotting
    figure();
    tStart = Pos.tS(1:nSamples);
    subplot(2,2,1)
      plot(tStart,oscStart);
      axis tight;
      hold on;
      ax = gca();
      plot([tStart(startIdx) tStart(startIdx)],ax.YLim);
      title('start of movement - position')
    subplot(2,2,2)
      plot(velSmooth);
      axis tight;
      hold on;
      ax = gca();
      plot([startIdx-startOffset startIdx-startOffset],ax.YLim);
      title('start of movement - smoothed vel')
  end

  oscEnd = Pos.xS(end-nSamples:end);
  oscSmooth = movmean(oscEnd,smoothWidth);
  velSmooth = abs(gradient(oscSmooth,Pos.dt)); % get velSmoothocity profile

  % sometimes there is vel. spike at start or end, get rid of it
  endOffset = 100;
  velSmooth = velSmooth(1:end-endOffset);

  speedLim = max(velSmooth)*(Pos.SPEED_LIM_PER/100);
  endIdxRel = find(velSmooth > speedLim,1,'last'); % find index of last "zero"
  endIdx = Pos.nShots - nSamples - 1 + endIdxRel; % turn end idx into absolute idx

  if Pos.verbosePlotting
    tEnd = Pos.tS(end-nSamples:end);
    subplot(2,2,3)
      plot(tEnd,oscEnd);
      axis tight;
      ax = gca();
      hold on;
      plot([tEnd(endIdxRel) tEnd(endIdxRel)],ax.YLim);
      title('end of movement - position')
    subplot(2,2,4)
      plot(velSmooth);
      axis tight;
      ax = gca();
      hold on;
      title('end of movement - smoothed vel')
      plot([endIdxRel endIdxRel],ax.YLim);
    sub_plot_title('Find_Scan_Oscillation_Range');
  end

  range = startIdx:endIdx;
  keepIdx = false(size(Pos.xS));
  keepIdx(range) = true;
  Pos.Done();
end
