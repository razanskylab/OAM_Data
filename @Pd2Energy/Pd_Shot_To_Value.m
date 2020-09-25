% Pd_Shot_To_Value(Pd2Energy,pdShots)
% takes pd SHOTS, i.e. 2D vector of form (nShots,pdSignal), i.e. (15000,280)
% and converts them into single values, i.e. something equivalent to energy
% but in arbitrary units
%
% Johannes Rebling, (johannesrebling@gmail.com), 2018

function Pd_Shot_To_Value(Obj,pdShots)
  % make sure pdShots are single, can't use couples here...
  pdShots = single(abs(pdShots)); % super fast if already single!

  tic;
  % remove noise floor
  Obj.VPrintF('[PD2E] Converting pd shots to energies (a.u.)...');
  noiseShots = pdShots(:, Obj.noiseWindow);
  noiseFloor = mean(noiseShots(:));
  if Obj.doRemoveNoise
    pdShots = bsxfun(@minus, pdShots, noiseFloor); % remove noise floor
  end
  
  % store shot shape for plotting and later validation
  % get overal max/min shots (ones with lowest and highest peaks...)
  [~,maxShotIdx] = max(max(pdShots,[],2));
  Obj.pdMax = squeeze(pdShots(maxShotIdx,:));
  [~,minShotIdx] = min(min(pdShots,[],2));
  Obj.pdMin = squeeze(pdShots(minShotIdx,:));
  % get shape of average shot
  Obj.pdMean = mean(pdShots);

  % only keep data within signal window
  pdShots = pdShots(:,Obj.signalWindow);

  % calculate PD energy values
  scalingFactor = 250e6; % used to keep a.u. pd values in a nice range
  % this helps the polynomial fit, is nicer for plotting and easier to read
  if ~Obj.sumBased
    fprintf('\n');
    short_warn('[PD2E] Using Obj.sumBased = false is really not recommended!');
    Obj.pd = squeeze(max(pdShots, [], 2)) .* Obj.dt .* scalingFactor;
  else
    Obj.pd = squeeze(sum(pdShots, 2)).* Obj.dt .* scalingFactor;
    Obj.Done();
  end


end
