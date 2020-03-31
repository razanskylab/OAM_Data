% Resample_Raw(SDO) @ SDO
% get reduced size version of the full raw matrix
% rsFactors - resample factors
% when integer, the raw = raw(1:rs(1):end,1:rs(2):end), which is very fast
% when float, we use griddedInterpolant, allows non-integer up and downsampling
% factors > 1 = downsampling
% factors < 1 = interpolation
%
% resamples raw, dt, prf and position data
% Johannes Rebling, (johannesrebling@gmail.com), 2018

function Resample_Raw(SDO)
  % FIXME - this also affects sampled positions etc
  % needs to be implemtented still once the rest works!
  tic;

  timeResample = SDO.reSampleFactors(1); % resample time signals
  spaceResample = SDO.reSampleFactors(2); % resample space signals
  if spaceResample ~= 1
    error('Space resampling not supported yet!');
  end

  isIntegerDownSampling = ~any(mod(SDO.reSampleFactors,1));

  if isIntegerDownSampling % fast and super simple case
    SDO.VPrintF('Resampling with integer steps (time=%i|space=%i)...',SDO.reSampleFactors);
    SDO.raw = SDO.raw(1:timeResample:end,1:spaceResample:end);
    SDO.prf = round(SDO.prf./timeResample); % freq. so divide
    SDO.dt = SDO.dt.*timeResample; % period, so multiply
    SDO.Done();
  else
    % NOTE Why we use griddedInterpolant
    % Both the interp family of functions and griddedInterpolant support N-D
    % grid-based interpolation. However, there are memory and performance benefits
    % to using the griddedInterpolant class over the interp functions. Moreover,
    % the griddedInterpolant class provides a single consistent interface for
    % working with gridded data in any number of dimensions.
    SDO.VPrintF('Resampling with non-integer steps (slowish):\n');
    SDO.VPrintF('x-positions...');
      dataType = class(SDO.xPos); % get data type to later restore it
      F = griddedInterpolant(single(SDO.xPos),'linear','none');
      shotGrid = 1:spaceResample:SDO.nShots;
      SDO.xPos = cast(F({shotGrid}),dataType);

    SDO.VPrintF('y-positions...');
      dataType = class(SDO.yPos); % get data type to later restore it
      F = griddedInterpolant(single(SDO.yPos),'linear','none');
      shotGrid = 1:spaceResample:SDO.nShots;
      SDO.yPos = cast(F({shotGrid}),dataType);

      SDO.VPrintF('prf...dt...');
      SDO.prf = round(SDO.prf./spaceResample); % freq. so divide
      SDO.dt = SDO.dt.*timeResample; % period, so multiply

      % NOTE raw interpolation must be done last, as otherwise SDO.nSamples and
      % SDO.nShots is not correct for other interpolations (as those are derived
      % from raw size)
      SDO.VPrintF('raw data...');
        dataType = class(SDO.raw); % get data type to later restore it
        F = griddedInterpolant(single(SDO.raw),'linear','none');
        shotGrid = 1:spaceResample:SDO.nShots;
        sampleGrid = 1:timeResample:SDO.nSamples;
        SDO.raw = cast(F({sampleGrid,shotGrid}),dataType);
      SDO.Done(t1);
  end
end
