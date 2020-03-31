% Get_Down_Sampled_Raw(SDO) @ SDO
% Johannes Rebling, (johannesrebling@gmail.com), 2018

function [dsRaw] = Get_Down_Sampled_Raw(SDO,dsFactors)
  % get reduced size version of the full raw matrix
  % dsFactors - down sample factors with
  %  [1:dsFactors(1):nSamples 1:dsFactors(2):nShots]
  % NOTE does not resample anything else, so only use this for plotting etc!
  % use SDO.Resample() for everything else!!!

  tic;
  dsFactorSamples = dsFactors(1); % skip samples
  dsFactorShots = dsFactors(2); % skip shots

  isIntegerDownSampling = ~any(mod(dsFactors,1));

  if isIntegerDownSampling % fast and super simple case
    dsRaw = SDO.raw(1:dsFactorSamples:end,1:dsFactorShots:end);
  else
    % NOTE Why we use griddedInterpolant
    % Both the interp family of functions and griddedInterpolant support N-D
    % grid-based interpolation. However, there are memory and performance benefits
    % to using the griddedInterpolant class over the interp functions. Moreover,
    % the griddedInterpolant class provides a single consistent interface for
    % working with gridded data in any number of dimensions.
    SDO.VPrintF('Downsampling with non-integer steps (slowish...)');
    dataType = class(SDO.raw); % get data type to later restore it
    F = griddedInterpolant(single(SDO.raw));
    shotGrid = 1:dsFactorSamples:SDO.nShots;
    sampleGrid = 1:dsFactorSamples:SDO.nSamples;
    dsRaw = cast(F({sampleGrid,shotGrid}),dataType);
    SDO.Done();
  end
end
