% Pd_Shot_To_Value(Pd2Energy,pdShots)
% takes pd SHOTS, i.e. 2D vector of form (nShots,pdSignal), i.e. (15000,280)
% and converts them into single values, i.e. something equivalent to energy
% but in arbitrary units
%
% Johannes Rebling, (johannesrebling@gmail.com), 2018

function Pd_Shot_To_Value(PDE,pdShots)

  % make sure pdShots are single, can't use couples here...
  pdShots = single(abs(pdShots)); % super fast if already single!

  % pd shots should have form nShots x nSamples
  % (it's recorded that way in the pd cal), so we make sure thats the case!
  % sizePdShots = size(pdShots);
  % nCol = sizePdShots(1);
  % nRows = sizePdShots(2);
%   if nRows > nCol
%     short_warn('[PDE] pdShots seems to be flipped... correcting this for you!');
%     pdShots = pdShots';
%   end

  % remove noise floor
  vprintf(PDE.verboseOutput, PDE.outTarget, '[PD2E] Converting pd shots to energies (a.u.)...');
  noiseShots = pdShots(:, PDE.noiseWindow);
  noiseFloor = mean(noiseShots(:));
  if PDE.doRemoveNoise
    pdShots = bsxfun(@minus, pdShots, noiseFloor); % remove noise floor
  end
  
  % store shot shape for plotting and later validation
  % get overal max/min shots (ones with lowest and highest peaks...)
  [~,maxShotIdx] = max(max(pdShots,[],2));
  PDE.pdMax = squeeze(pdShots(maxShotIdx,:));
  [~,minShotIdx] = min(min(pdShots,[],2));
  PDE.pdMin = squeeze(pdShots(minShotIdx,:));
  % get shape of average shot
  PDE.pdMean = mean(pdShots);

  % only keep data within signal window
  pdShots = pdShots(:,PDE.signalWindow);

  % calculate PD energy values
  scalingFactor = 250e6; % used to keep a.u. pd values in a nice range
  % this helps the polynomial fit, is nicer for plotting and easier to read
  if ~PDE.sumBased
    fprintf('\n');
    short_warn('[PD2E] Using PDE.sumBased = false is really not recommended!');
    PDE.pd = squeeze(max(pdShots, [], 2)) .* PDE.dt .* scalingFactor;
  else
    PDE.pd = squeeze(sum(pdShots, 2)).* PDE.dt .* scalingFactor;
    if PDE.verboseOutput
      vprintf(PDE.verboseOutput,PDE.outTarget,'done.\n');
    end
  end


end
